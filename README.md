<!-- Header Banner -->
<div align="center">

<img src="assets/images/mfu-fixflow.png" alt="MFU FixFlow" width="150"/>

# MFU FixFlow

### 🏢 Dormitory Maintenance Request System

*A modern, role-based facility management platform built for Mae Fah Luang University*

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=flat-square&logo=supabase&logoColor=white)](https://supabase.com)
[![Firebase](https://img.shields.io/badge/Firebase-FCM-FFCA28?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-brightgreen?style=flat-square)]()
[![License](https://img.shields.io/badge/License-University%20Project-blue?style=flat-square)]()

<br/>

[Features](#-features) · [Tech Stack](#-tech-stack) · [Architecture](#-architecture) · [Getting Started](#-getting-started) · [Roles & Permissions](#-roles--permissions) · [Security](#-security)

<br/>

---

</div>

## 📋 About

> **MFU FixFlow** bridges the gap between students experiencing facility issues and the maintenance teams responsible for resolving them.

Traditional dormitory maintenance relies on phone calls, paper forms, or walk-in requests — leading to lost tickets, unclear priorities, and slow response times. **FixFlow** digitizes this entire workflow into a streamlined mobile & web experience.

**Key outcomes:**
- ⚡ **Faster response** — issues are routed instantly to the right team
- 📸 **Visual evidence** — photo attachments eliminate miscommunication
- 📊 **Full transparency** — every stakeholder can track progress in real-time
- 🔔 **Zero missed tickets** — push notifications keep everyone in the loop

---

## ✨ Features

<table>
<tr>
<td width="50%" valign="top">

### 📝 Ticket Lifecycle
- Create maintenance requests with **photo evidence**
- Automatic routing based on **building assignment**
- Real-time **status tracking** from submission → resolution
- Full ticket history and **audit trail**
- Delete or update tickets with proper authorization

</td>
<td width="50%" valign="top">

### 🔔 Notification Engine
- **Real-time push notifications** via Firebase Cloud Messaging (v1 API)
- Intelligent **role-based routing** — only relevant users get notified
- In-app **notification inbox** with read/unread tracking
- **Auto-cleanup** of stale or unregistered device tokens
- Background notification handling for closed app states

</td>
</tr>
<tr>
<td width="50%" valign="top">

### 👥 Access Control
- **Six distinct user roles** with granular permission levels
- **Building-specific assignment** for managers and technicians
- Secure IT Admin portal for **full user CRUD operations**
- Session management with **automatic token refresh**
- PKCE authentication flow for enhanced security

</td>
<td width="50%" valign="top">

### 📊 Dashboard & Management
- Role-tailored **overview dashboard** with real-time data streams
- **Search and filter** across all tickets and users
- **Multi-language support** (Thai & English) with user preference storage
- Responsive design for both **mobile and web** platforms
- Building-scoped views for **focused management**

</td>
</tr>
</table>

---

## 🛠 Tech Stack

<table>
<tr>
<td align="center" width="120">
<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/flutter/flutter-original.svg" width="48" height="48" alt="Flutter" />
<br><strong>Flutter</strong>
<br><sub>Frontend</sub>
</td>
<td align="center" width="120">
<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/dart/dart-original.svg" width="48" height="48" alt="Dart" />
<br><strong>Dart</strong>
<br><sub>Language</sub>
</td>
<td align="center" width="120">
<img src="https://cf-assets.www.cloudflare.com/slt3lc6tev37/5FpAMKbNmKOY9W8If3JILF/ee09a5d0e9c6fc7e94c5d8f25c6f1e93/supabase-logo-icon_1.svg" width="48" height="48" alt="Supabase" />
<br><strong>Supabase</strong>
<br><sub>Backend</sub>
</td>
<td align="center" width="120">
<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/firebase/firebase-plain.svg" width="48" height="48" alt="Firebase" />
<br><strong>Firebase</strong>
<br><sub>Notifications</sub>
</td>
<td align="center" width="120">
<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/postgresql/postgresql-original.svg" width="48" height="48" alt="PostgreSQL" />
<br><strong>PostgreSQL</strong>
<br><sub>Database</sub>
</td>
</tr>
</table>

| Component | Technology | Details |
|:---|:---|:---|
| **UI Framework** | Flutter 3.10+ | Material Design 3, responsive layouts |
| **State & Data** | Supabase Realtime | Live data streams for dashboards |
| **Authentication** | Supabase Auth | PKCE flow, session management, token refresh |
| **Push Notifications** | Firebase FCM v1 | HTTP v1 API via Supabase Edge Functions |
| **File Storage** | Supabase Storage | Ticket photo uploads with public URL generation |
| **Edge Functions** | Deno (TypeScript) | Server-side notification dispatch |
| **Environment Config** | flutter_dotenv | Runtime secret loading from `.env` |

---

## 🏗 Architecture

```
┌──────────────────────────────────────────────────────────┐
│                     Client Layer                          │
│                                                          │
│   ┌─────────────┐    ┌─────────────┐    ┌────────────┐   │
│   │  Auth Flow   │    │  Dashboard   │    │  Tickets   │   │
│   │  Login/Role  │    │  Home/Inbox  │    │  CRUD/View │   │
│   └──────┬──────┘    └──────┬──────┘    └─────┬──────┘   │
│          │                  │                  │          │
│   ┌──────▼──────────────────▼──────────────────▼──────┐   │
│   │          NotificationService (FCM Client)         │   │
│   ├───────────────────────────────────────────────────┤   │
│   │          Supabase Flutter SDK (Auth/DB/Storage)   │   │
│   └──────────────────────┬────────────────────────────┘   │
│           Flutter App    │   (Android + Web)              │
└──────────────────────────┼────────────────────────────────┘
                           │ HTTPS
┌──────────────────────────▼────────────────────────────────┐
│                    Supabase Cloud                          │
│                                                           │
│   ┌─────────────────┐  ┌──────────────────────────────┐   │
│   │   PostgreSQL     │  │   Edge Function              │   │
│   │  ┌────────────┐  │  │   send-notification          │   │
│   │  │ profiles   │  │  │                              │   │
│   │  │ tickets    │  │  │  ┌────────────────────────┐  │   │
│   │  │ push_tokens│  │  │  │ 1. Fetch FCM tokens    │  │   │
│   │  │ room_logs  │  │  │  │ 2. Generate OAuth JWT  │  │   │
│   │  │ notificati…│  │  │  │ 3. Call FCM v1 API     │  │   │
│   │  └────────────┘  │  │  │ 4. Auto-clean stale    │  │   │
│   │                  │  │  └───────────┬────────────┘  │   │
│   │  Auth / Storage  │  │              │               │   │
│   └─────────────────┘  └──────────────┼───────────────┘   │
│                                       │                   │
└───────────────────────────────────────┼───────────────────┘
                                        │ HTTPS
                           ┌────────────▼────────────┐
                           │  Firebase Cloud Messaging│
                           │       (FCM v1 API)       │
                           │                          │
                           │  → Android Push          │
                           │  → Web Push              │
                           └──────────────────────────┘
```

---

## 📁 Project Structure

```
mfu_fixflow/
│
├── 📂 lib/
│   ├── main.dart                          # App entry point & initialization
│   ├── supabase_config.dart               # Supabase credentials (from .env)
│   ├── firebase_options.dart              # Firebase credentials (from .env)
│   │
│   ├── 📂 features/
│   │   ├── 📂 auth/
│   │   │   ├── login_screen.dart          # Email/password login
│   │   │   └── role_selection_screen.dart  # Post-login role routing
│   │   │
│   │   ├── 📂 dashboard/
│   │   │   └── home_screen.dart           # Main dashboard, notifications, profile
│   │   │
│   │   ├── 📂 report/
│   │   │   ├── report_screen.dart         # Create new ticket with photo
│   │   │   └── ticket_detail_screen.dart  # View/edit/delete ticket details
│   │   │
│   │   └── 📂 admin/
│   │       ├── user_management_screen.dart # IT Admin: full user CRUD
│   │       ├── technician_screen.dart      # Technician work queue
│   │       └── manager_screen.dart         # Manager oversight panel
│   │
│   └── 📂 services/
│       └── notification_service.dart       # FCM init, token management, send API
│
├── 📂 supabase/
│   └── 📂 functions/
│       └── 📂 send-notification/
│           └── index.ts                    # Edge Function: FCM v1 dispatcher
│
├── 📂 android/                             # Android platform config
├── 📂 web/                                 # Web platform config
├── 📂 assets/images/                       # App logo & images
│
├── .env.example                            # 🔑 Environment variable template
├── .gitignore                              # Git exclusion rules
├── pubspec.yaml                            # Flutter dependencies
└── README.md                               # You are here!
```

---

## 🚀 Getting Started

### Prerequisites

| Requirement | Version | Link |
|:---|:---|:---|
| Flutter SDK | ≥ 3.10 | [Install Flutter](https://docs.flutter.dev/get-started/install) |
| Dart SDK | ≥ 3.10 | Included with Flutter |
| Supabase Project | — | [Create Project](https://supabase.com/dashboard) |
| Firebase Project | — | [Firebase Console](https://console.firebase.google.com/) |

### Quick Start

```bash
# 1️⃣ Clone the repository
git clone https://github.com/Dechawat-Wetprasit/mfu_fixflow.git
cd mfu_fixflow

# 2️⃣ Configure environment variables
cp .env.example .env
# ✏️ Edit .env with your Supabase & Firebase credentials

# 3️⃣ Add Firebase config for Android
# Download google-services.json from Firebase Console → Project Settings → Android
# Place it in: android/app/google-services.json

# 4️⃣ Install dependencies
flutter pub get

# 5️⃣ Launch the app
flutter run                    # Default device
flutter run -d chrome          # Run on Web
flutter run -d <device_id>     # Run on specific Android device
```

### Environment Variables Reference

Create a `.env` file in the project root with the following variables:

| Variable | Required | Description |
|:---|:---:|:---|
| `SUPABASE_URL` | ✅ | Supabase project URL |
| `SUPABASE_ANON_KEY` | ✅ | Supabase anonymous/public API key |
| `FIREBASE_API_KEY_WEB` | ✅ | Firebase Web API key |
| `FIREBASE_API_KEY_ANDROID` | ✅ | Firebase Android API key |
| `FIREBASE_PROJECT_ID` | ✅ | Firebase project identifier |
| `FIREBASE_MESSAGING_SENDER_ID` | ✅ | FCM sender ID |
| `FIREBASE_APP_ID_WEB` | ✅ | Firebase Web app ID |
| `FIREBASE_APP_ID_ANDROID` | ✅ | Firebase Android app ID |
| `FIREBASE_AUTH_DOMAIN` | ✅ | Firebase authentication domain |
| `FIREBASE_STORAGE_BUCKET` | ✅ | Firebase storage bucket URL |
| `FIREBASE_MEASUREMENT_ID` | ⬜ | Google Analytics measurement ID |

> 📌 See [`.env.example`](.env.example) for a ready-to-use template.

---

## 👥 Roles & Permissions

```
IT Admin ──────────────────────────────────────────── Full System Access
    │
    ├── Head Manager ─────────────────────────── All Buildings
    │       └── Manager ──────────────────────── Assigned Building
    │
    ├── Head Technician ──────────────────────── Team Management
    │       └── Technician ───────────────────── Assigned Repairs
    │
    └── Student ──────────────────────────────── Submit & Track
```

| Role | Create Ticket | View Tickets | Manage Tickets | Manage Users | Scope |
|:---|:---:|:---:|:---:|:---:|:---|
| **Student** | ✅ | Own only | ❌ | ❌ | Personal tickets |
| **Manager** | ❌ | ✅ | ✅ | ❌ | Assigned building |
| **Head Manager** | ❌ | ✅ | ✅ | ❌ | All buildings |
| **Technician** | ❌ | ✅ | ✅ Update status | ❌ | Assigned tasks |
| **Head Technician** | ❌ | ✅ | ✅ | ❌ | Team workload |
| **IT Admin** | ❌ | ✅ | ✅ | ✅ Full CRUD | Entire system |

---

## 🔒 Security

| Measure | Implementation |
|:---|:---|
| **Secret Management** | All credentials loaded at runtime from `.env` via [`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv) |
| **Git Protection** | `.env`, `google-services.json`, and `firebase_options.dart` are excluded from version control |
| **Authentication** | PKCE (Proof Key for Code Exchange) flow via Supabase Auth |
| **Token Security** | Automatic JWT refresh with 5-minute buffer before expiry |
| **Server-side Secrets** | Supabase Edge Functions use isolated environment variables |
| **Device Token Hygiene** | Stale/unregistered FCM tokens are auto-deleted from the database |

---

## 📄 License

This project was developed as an academic project at **Mae Fah Luang University**, Chiang Rai, Thailand.

---

<div align="center">

**Built with ❤️ using Flutter & Supabase**

*MFU FixFlow — Making dormitory maintenance effortless*

</div>
