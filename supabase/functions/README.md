# Supabase Edge Functions สำหรับ MFU FIXFLOW

## การติดตั้งและ Deploy

### 1. ติดตั้ง Supabase CLI

```bash
# Windows (PowerShell)
scoop install supabase

# หรือใช้ npm
npm install -g supabase
```

### 2. Login เข้า Supabase

```bash
supabase login
```

### 3. Link โปรเจค

```bash
supabase link --project-ref <YOUR_PROJECT_REF>
```

หา Project Ref ได้จาก URL ของ Supabase Dashboard:
`https://app.supabase.com/project/<YOUR_PROJECT_REF>`

### 4. Deploy Functions

**สำคัญ:** ต้องใส่ `--no-verify-jwt` ทุกครั้งที่ deploy manage-users ไม่งั้นจะได้ **401 Invalid JWT** (gateway ตรวจ JWT ก่อนถึงโค้ดเรา)

```bash
# จาก root โปรเจกต์ (mfu_fixflow)
supabase functions deploy manage-users --no-verify-jwt
```

หรือดับเบิลคลิกรันสคริปต์:
- **Windows:** `supabase/functions/deploy-manage-users.bat`
- **PowerShell:** `.\supabase\functions\deploy-manage-users.ps1`

ห้ามใช้ `supabase functions deploy manage-users` โดยไม่มี `--no-verify-jwt`

## Functions ที่มี

### manage-users

จัดการผู้ใช้งานในระบบ (สร้าง, แก้ไข, ลบ)

**Endpoint:** `https://<project-ref>.supabase.co/functions/v1/manage-users`

**Method:** POST

**Headers:**
```
Authorization: Bearer <user-token>
Content-Type: application/json
```

**Body Examples:**

1. สร้างผู้ใช้ใหม่:
```json
{
  "action": "create",
  "userData": {
    "email": "tech1@mfu.ac.th",
    "password": "password123",
    "full_name": "ช่าง ทดสอบ",
    "role": "technician",
    "responsible_building": "M1"
  }
}
```

2. แก้ไขผู้ใช้:
```json
{
  "action": "update",
  "userData": {
    "user_id": "uuid-here",
    "full_name": "ช่าง ทดสอบ แก้ไข",
    "role": "head_technician",
    "responsible_building": "M2"
  }
}
```

3. ลบผู้ใช้:
```json
{
  "action": "delete",
  "userData": {
    "user_id": "uuid-here"
  }
}
```

## การทดสอบ

```bash
# ทดสอบ function ในเครื่อง
supabase functions serve manage-users

# ทดสอบด้วย curl
curl -i --location --request POST 'http://localhost:54321/functions/v1/manage-users' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"action":"create","userData":{"email":"test@mfu.ac.th","password":"123456","full_name":"Test User","role":"technician"}}'
```

## หมายเหตุ

- เฉพาะผู้ใช้ที่มี role = 'manager' เท่านั้นที่สามารถเรียกใช้ functions เหล่านี้ได้
- ต้องส่ง Authorization token ที่ถูกต้องทุกครั้ง
- Function จะใช้ SUPABASE_SERVICE_ROLE_KEY ในการดำเนินการกับ Auth
