@echo off
REM Deploy manage-users โดยปิด JWT verification ที่ gateway
REM ต้องใช้ --no-verify-jwt ทุกครั้ง ไม่งั้นจะได้ 401 Invalid JWT
cd /d "%~dp0..\.."
supabase functions deploy manage-users --no-verify-jwt
pause
