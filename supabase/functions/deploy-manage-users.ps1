# Deploy manage-users Edge Function โดยปิด JWT verification ที่ gateway
# ต้องรันคำสั่งนี้ทุกครั้งที่ deploy (สำคัญมาก — ถ้าไม่ใส่ --no-verify-jwt จะได้ 401 Invalid JWT)
$projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
Set-Location $projectRoot
supabase functions deploy manage-users --no-verify-jwt
