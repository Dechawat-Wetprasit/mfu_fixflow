// @ts-nocheck
// Supabase Edge Function for User Management
// ใช้การ verify JWT เองด้วย JWKS (วิธีที่ Supabase แนะนำ) แทน auth.getUser() เพื่อความเสถียรและรองรับ JWT แบบใหม่
/// <reference types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts" />

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import * as jose from 'jsr:@panva/jose@6'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = (Deno.env.get('SUPABASE_URL') ?? '').replace(/\/$/, '')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

    if (!supabaseUrl || !serviceRoleKey) {
      return jsonResponse({ error: 'Missing Supabase environment configuration' }, 500)
    }

    const authHeader = req.headers.get('Authorization') ?? ''
    if (!authHeader.startsWith('Bearer ')) {
      return jsonResponse({ error: 'Missing or invalid authorization header' }, 401)
    }

    const token = authHeader.replace(/^Bearer\s+/i, '').trim()
    if (!token) return jsonResponse({ error: 'Missing token' }, 401)

    // Verify JWT เองใน function (gateway ใช้ verify_jwt = false แล้ว)
    // ลอง JWKS ก่อน (โปรเจกต์ใหม่) ถ้าไม่ผ่านลอง Legacy secret (โปรเจกต์เก่า)
    let userId: string
    try {
      const jwksUrl = `${supabaseUrl}/auth/v1/.well-known/jwks.json`
      const JWKS = jose.createRemoteJWKSet(new URL(jwksUrl))
      const issuer = Deno.env.get('SB_JWT_ISSUER') ?? `${supabaseUrl}/auth/v1`
      const { payload } = await jose.jwtVerify(token, JWKS, { issuer })
      const sub = payload.sub
      if (typeof sub === 'string' && sub) {
        userId = sub
      } else {
        return jsonResponse({ error: 'Invalid JWT payload' }, 401)
      }
    } catch {
      const legacySecret = Deno.env.get('SUPABASE_JWT_SECRET')
      if (legacySecret) {
        try {
          const key = new TextEncoder().encode(legacySecret)
          const { payload } = await jose.jwtVerify(token, key, {
            algorithms: ['HS256'],
            issuer: Deno.env.get('SB_JWT_ISSUER') ?? `${supabaseUrl}/auth/v1`,
          })
          const sub = payload.sub
          if (typeof sub === 'string' && sub) {
            userId = sub
          } else {
            return jsonResponse({ error: 'Invalid JWT payload' }, 401)
          }
        } catch {
          return jsonResponse({ error: 'Invalid or expired token' }, 401)
        }
      } else {
        return jsonResponse({ error: 'Invalid or expired token' }, 401)
      }
    }

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    })

    const { data: roleRow, error: roleError } = await supabaseAdmin
      .from('profiles')
      .select('role')
      .eq('id', userId)
      .maybeSingle()

    if (roleError) throw roleError
    if (!roleRow || !['admin', 'it_admin'].includes(roleRow.role)) {
      return jsonResponse({ error: 'Forbidden' }, 403)
    }

    let body: { action?: string; userData?: Record<string, unknown> }
    try {
      body = await req.json()
    } catch {
      return jsonResponse({ error: 'Invalid JSON body' }, 400)
    }

    const { action, userData } = body
    if (!action || !userData || typeof userData !== 'object') {
      return jsonResponse({ error: 'Missing action or userData' }, 400)
    }

    let result

    switch (action) {
      case 'create':
        const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
          email: userData.email,
          password: userData.password,
          email_confirm: true,
          user_metadata: {
            full_name: userData.full_name,
            role: userData.role,
            responsible_building: userData.responsible_building || null,
          }
        })

        if (createError) throw createError

        await supabaseAdmin.from('profiles').insert({
          id: newUser.user.id,
          email: userData.email,
          full_name: userData.full_name,
          role: userData.role,
          responsible_building: userData.responsible_building || null,
        })

        result = { success: true, user: newUser.user }
        break

      case 'update':
        const { data: updatedUser, error: updateError } = await supabaseAdmin.auth.admin.updateUserById(
          userData.user_id,
          {
            user_metadata: {
              full_name: userData.full_name,
              role: userData.role,
              responsible_building: userData.responsible_building || null,
            }
          }
        )

        if (updateError) throw updateError

        await supabaseAdmin
          .from('profiles')
          .update({
            full_name: userData.full_name,
            role: userData.role,
            responsible_building: userData.responsible_building || null,
          })
          .eq('id', userData.user_id)

        result = { success: true, user: updatedUser.user }
        break

      case 'delete':
        const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(
          userData.user_id
        )

        if (deleteError) throw deleteError

        await supabaseAdmin
          .from('profiles')
          .delete()
          .eq('id', userData.user_id)

        result = { success: true }
        break

      default:
        throw new Error('Unknown action: ' + action)
    }

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
