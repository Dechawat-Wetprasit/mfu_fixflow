import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4'
import { SignJWT, importPKCS8 } from "https://deno.land/x/jose@v4.14.4/index.ts"

// ฟังก์ชันสร้าง Access Token จาก Service Account สำหรับ Google API
async function getAccessToken(serviceAccount: any): Promise<string> {
  const privateKey = await importPKCS8(serviceAccount.private_key, "RS256");
  const jwt = await new SignJWT({
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuedAt()
    .setExpirationTime("1h")
    .sign(privateKey);

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const data = await response.json();
  if (!response.ok) {
    throw new Error(`Failed to generate token: ${data.error_description || data.error}`);
  }
  return data.access_token;
}

// รูปแบบข้อมูลเตรียมส่ง
interface NotificationJob {
  userIds: string[];
  title: string;
  body: string;
}

// โครงสร้าง Request Body แบบใหม่ที่รับจาก Flutter โดยตรง
interface DirectNotificationRequest {
  target_user_id: string;
  title: string;
  body: string;
  record_id?: string;
  action?: string;
}

serve(async (req) => {
  // 1. จัดการ CORS ให้สอดคล้องกับการเรียกจาก Flutter/Web
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  // ตอบกลับ OPTIONS (Preflight request)
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const payload: DirectNotificationRequest = await req.json()
    const { target_user_id, title, body, record_id, action } = payload;

    if (!target_user_id || !title || !body) {
      console.warn("[Abort] Missing required fields in request payload");
      return new Response(JSON.stringify({ error: 'Missing required fields: target_user_id, title, body' }), { headers: corsHeaders, status: 400 })
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    console.log(`[Process] Preparing to send push notification to user: ${target_user_id}`);

    // INSERT into notifications table to show in the app's notification bell (Inbox)
    const { error: insertNotiError } = await supabaseClient
      .from('notifications')
      .insert({
        user_id: target_user_id,
        title: title,
        message: body, // home_screen.dart uses 'message' column instead of 'body'
        is_read: false
      });

    if (insertNotiError) {
      console.error("[DB Error] Failed to insert into notifications table:", insertNotiError);
    }

    // 2. ดึง FCM Token ของ User คนนั้นออกมาทั้งหมดแบบตรงๆ
    const { data: userTokens, error: tokenErr } = await supabaseClient
      .from('push_tokens')
      .select('fcm_token')
      .eq('user_id', target_user_id)

    if (tokenErr) {
      console.error("[DB Error] Failed to fetch device tokens:", tokenErr);
      return new Response(JSON.stringify({ error: 'Failed to query database for tokens' }), { headers: corsHeaders, status: 500 })
    }

    if (!userTokens || userTokens.length === 0) {
      console.log(`[Abort] No registered FCM token found for user: ${target_user_id}`);
      return new Response(JSON.stringify({ success: true, message: 'No registered tokens found. Skipped.' }), { headers: corsHeaders, status: 200 })
    }

    const fcmTokens = userTokens.map(t => t.fcm_token).filter(Boolean)
    if (fcmTokens.length === 0) {
      return new Response(JSON.stringify({ success: true, message: 'Tokens structure is empty.' }), { headers: corsHeaders, status: 200 })
    }

    // --- เตรียมส่ง Push Notification ตรงเข้า Google API V1 ---
    const serviceAccountStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
    if (!serviceAccountStr) {
      throw new Error("Missing FIREBASE_SERVICE_ACCOUNT secret.");
    }
    const serviceAccount = JSON.parse(serviceAccountStr);
    const projectId = serviceAccount.project_id;
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    // 3. ดึง Access Token สดๆ
    const accessToken = await getAccessToken(serviceAccount);
    let totalSent = 0;

    // ยิงตรงเข้าหา API รุ่น V1 ต้องยิงทีละ Token
    for (const token of fcmTokens) {
      try {
        const fcmResponse = await fetch(fcmUrl, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: token,
              notification: {
                title: title,
                body: body,
              },
              data: {
                action: action ?? "report_update",
                record_id: String(record_id ?? '')
              },
              android: {
                priority: "high",
                notification: { channel_id: "high_importance_channel", sound: "default" }
              },
              apns: {
                payload: { aps: { sound: "default" } }
              }
            }
          })
        });

        if (!fcmResponse.ok) {
          const errorData = await fcmResponse.text();
          console.error(`[FCM Error] Token = ${token}: ${fcmResponse.status} ${fcmResponse.statusText} - ${errorData}`);

          // 4. Auto-cleanup: ถ้า Token นี้ตายแล้ว (แอปถูกลบ/หมดอายุ หรือเป็น Error 404 UNREGISTERED) ให้ลบออกจาก DB
          if (fcmResponse.status === 404 || errorData.includes("UNREGISTERED")) {
            console.log(`[Auto-Clean] Deleting invalid/stale token from DB: ${token}`);
            await supabaseClient.from('push_tokens').delete().eq('fcm_token', token);
          }
        } else {
          console.log(`[FCM Success] Sent to token: ${token}`);
          totalSent++;
        }
      } catch (e) {
        console.error(`[FCM Request Exception] Token = ${token}:`, e);
      }
    }

    console.log(`[Finished] Dispatched ${totalSent} / ${fcmTokens.length} notification(s).`)
    return new Response(
      JSON.stringify({ success: true, dispatched: totalSent, total_devices: fcmTokens.length }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  } catch (error) {
    console.error('[Fatal Error] Function crashed:', error);
    return new Response(JSON.stringify({ error: String(error) }), { headers: corsHeaders, status: 500 }) // Add CORS Header
  }
})
