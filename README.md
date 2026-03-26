<p align="center">
  <img src="assets/images/mfu-fixflow.png" alt="MFU FixFlow Logo" width="120"/>
</p>

<h1 align="center">MFU FixFlow</h1>

<p align="center">
  <strong>ระบบแจ้งซ่อมหอพักมหาวิทยาลัยแม่ฟ้าหลวง</strong><br/>
  <em>Dormitory Maintenance Request System for Mae Fah Luang University</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.10+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase"/>
  <img src="https://img.shields.io/badge/Firebase-FCM-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"/>
</p>

---

## 📖 เกี่ยวกับโปรเจค | About

**MFU FixFlow** คือแอปพลิเคชัน Flutter สำหรับจัดการระบบแจ้งซ่อมบำรุงรักษาหอพักของมหาวิทยาลัยแม่ฟ้าหลวง ออกแบบมาเพื่อให้นักศึกษาสามารถแจ้งปัญหาด้านสิ่งอำนวยความสะดวกภายในหอพัก รวมถึงช่วยให้เจ้าหน้าที่ผู้จัดการและช่างเทคนิคสามารถติดตามและจัดการงานซ่อมได้อย่างมีประสิทธิภาพ

**MFU FixFlow** is a Flutter application for managing dormitory maintenance requests at Mae Fah Luang University. It allows students to report facility issues, while enabling managers and technicians to efficiently track and handle repairs.

---

## ✨ คุณสมบัติ | Features

| Feature | Description |
|---|---|
| 🎫 **แจ้งซ่อม** | นักศึกษาแจ้งปัญหาพร้อมแนบรูปภาพ |
| 👥 **ระบบบทบาท** | รองรับหลายบทบาท: นักศึกษา, ผู้จัดการหอ, หัวหน้าผู้จัดการหอ, ช่างเทคนิค, หัวหน้าช่าง, Admin |
| 🔔 **Push Notifications** | แจ้งเตือนแบบ Real-time ผ่าน Firebase Cloud Messaging |
| 📊 **Dashboard** | แดชบอร์ดภาพรวมสำหรับผู้จัดการและช่าง |
| 🏢 **จัดการตามอาคาร** | กรองและมอบหมายงานตามอาคารหอพัก |
| 👤 **จัดการผู้ใช้** | ระบบจัดการผู้ใช้สำหรับ IT Admin |
| 🌐 **สองภาษา** | รองรับภาษาไทยและอังกฤษ |

---

## 🛠 เทคโนโลยี | Tech Stack

- **Frontend**: [Flutter](https://flutter.dev/) (Dart)
- **Backend**: [Supabase](https://supabase.com/) (PostgreSQL + Edge Functions)
- **Push Notifications**: [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) (FCM v1 API)
- **Authentication**: Supabase Auth (PKCE Flow)
- **Storage**: Supabase Storage (สำหรับรูปภาพ)

---

## 📁 โครงสร้างโปรเจค | Project Structure

```
mfu_fixflow/
├── lib/
│   ├── main.dart                     # Entry point
│   ├── supabase_config.dart          # Supabase configuration (from .env)
│   ├── firebase_options.dart         # Firebase configuration (from .env)
│   ├── features/
│   │   ├── auth/                     # Login & Role Selection
│   │   ├── dashboard/                # Home Screen & Notifications
│   │   ├── report/                   # Ticket Reporting & Details
│   │   └── admin/                    # User Management, Technician & Manager Screens
│   └── services/
│       └── notification_service.dart # FCM Push Notification Handler
├── supabase/
│   └── functions/
│       └── send-notification/        # Supabase Edge Function (FCM)
├── assets/
│   └── images/                       # App icons & images
├── .env.example                      # Environment variable template
└── pubspec.yaml
```

---

## 🚀 การติดตั้ง | Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.10
- [Dart SDK](https://dart.dev/get-dart) ≥ 3.10
- [Supabase Project](https://supabase.com/)
- [Firebase Project](https://console.firebase.google.com/)

### 1. Clone Repository

```bash
git clone https://github.com/Dechawat-Wetprasit/mfu_fixflow.git
cd mfu_fixflow
```

### 2. ตั้งค่า Environment Variables

คัดลอกไฟล์ `.env.example` เป็น `.env` แล้วใส่ค่าจริง:

```bash
cp .env.example .env
```

แก้ไขไฟล์ `.env` ให้ตรงกับ Supabase และ Firebase project ของคุณ:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
FIREBASE_API_KEY_WEB=your-firebase-web-api-key
FIREBASE_API_KEY_ANDROID=your-firebase-android-api-key
# ... ดูรายละเอียดใน .env.example
```

### 3. ติดตั้ง Dependencies

```bash
flutter pub get
```

### 4. ตั้งค่า Firebase

- วาง `google-services.json` ใน `android/app/`
- (iOS) วาง `GoogleService-Info.plist` ใน `ios/Runner/`

### 5. รันแอป

```bash
flutter run
```

---

## 👥 บทบาทผู้ใช้ | User Roles

| Role | หน้าที่ |
|---|---|
| **Student** | แจ้งซ่อม, ติดตามสถานะ |
| **Manager** | ดูแลงานซ่อมในอาคารที่รับผิดชอบ |
| **Head Manager** | ดูภาพรวมทุกอาคาร, มอบหมายงาน |
| **Technician** | รับงานซ่อม, อัพเดทสถานะ |
| **Head Technician** | จัดการทีมช่าง |
| **IT Admin** | จัดการผู้ใช้ทั้งระบบ |

---

## 📝 License

This project is developed as a university project for Mae Fah Luang University.

---

<p align="center">
  Made with ❤️ by MFU FixFlow Team
</p>
