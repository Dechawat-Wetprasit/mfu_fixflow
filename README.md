<p align="center">
  <img src="assets/images/mfu-fixflow.png" alt="MFU FixFlow" width="140"/>
</p>

<h1 align="center">MFU FixFlow</h1>

<p align="center">
  <strong>Dormitory Maintenance Request System</strong><br/>
  <sub>Built for Mae Fah Luang University</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.10+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase"/>
  <img src="https://img.shields.io/badge/Firebase-FCM-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Web-green?style=for-the-badge" alt="Platform"/>
</p>

<p align="center">
  <a href="#-features">Features</a> •
  <a href="#-tech-stack">Tech Stack</a> •
  <a href="#-architecture">Architecture</a> •
  <a href="#-getting-started">Getting Started</a> •
  <a href="#-user-roles">User Roles</a>
</p>

---

## 📋 Overview

**MFU FixFlow** is a cross-platform mobile & web application designed to streamline the dormitory maintenance workflow at Mae Fah Luang University. Students can submit repair requests with photo evidence, while managers and technicians can track, assign, and resolve issues — all with real-time push notifications.

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🎫 Ticket Management
- Submit maintenance requests with photo attachments
- Real-time status tracking from submission to completion
- Categorized by building and issue type

### 🔔 Smart Notifications
- Real-time push notifications via Firebase Cloud Messaging
- Role-based notification routing
- Auto-cleanup of stale device tokens

</td>
<td width="50%">

### 👥 Role-Based Access Control
- Six distinct user roles with granular permissions
- Building-specific assignment for managers and technicians
- Secure user management portal for IT Admins

### 📊 Dashboard & Analytics
- Overview dashboard for managers and technicians
- Filter and search across all tickets
- Notification inbox with read/unread tracking

</td>
</tr>
</table>

---

## 🛠 Tech Stack

| Layer | Technology | Purpose |
|:---:|:---:|:---|
| **Frontend** | Flutter & Dart | Cross-platform UI (Android + Web) |
| **Backend** | Supabase (PostgreSQL) | Database, Auth, Storage, Edge Functions |
| **Notifications** | Firebase Cloud Messaging | Push notifications via FCM v1 API |
| **Auth** | Supabase Auth (PKCE) | Secure authentication flow |
| **Storage** | Supabase Storage | Photo/image uploads for tickets |

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Flutter App                        │
│  ┌──────────┐  ┌──────────┐  ┌───────────────────┐  │
│  │   Auth   │  │ Dashboard │  │  Report/Tickets   │  │
│  └────┬─────┘  └────┬─────┘  └────────┬──────────┘  │
│       │              │                 │              │
│  ┌────▼──────────────▼─────────────────▼──────────┐  │
│  │            Supabase Client SDK                  │  │
│  └────────────────────┬───────────────────────────┘  │
└───────────────────────┼──────────────────────────────┘
                        │
         ┌──────────────▼──────────────┐
         │        Supabase Cloud       │
         │  ┌──────────────────────┐   │
         │  │   PostgreSQL (DB)    │   │
         │  ├──────────────────────┤   │
         │  │   Edge Functions     │──────► Firebase FCM v1 API
         │  ├──────────────────────┤   │
         │  │   Auth / Storage     │   │
         │  └──────────────────────┘   │
         └─────────────────────────────┘
```

---

## 📁 Project Structure

```
mfu_fixflow/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── supabase_config.dart           # Supabase config (reads from .env)
│   ├── firebase_options.dart          # Firebase config (reads from .env)
│   ├── features/
│   │   ├── auth/                      # Login & Role Selection
│   │   ├── dashboard/                 # Home, Notifications, Profile
│   │   ├── report/                    # Ticket Creation & Details
│   │   └── admin/                     # User Management, Technician & Manager Views
│   └── services/
│       └── notification_service.dart  # FCM Push Notification Handler
├── supabase/
│   └── functions/
│       └── send-notification/         # Edge Function: FCM Dispatcher
├── android/                           # Android platform
├── web/                               # Web platform
├── assets/images/                     # App icons & images
├── .env.example                       # Environment variable template
└── pubspec.yaml                       # Dependencies
```

---

## 🚀 Getting Started

### Prerequisites

| Tool | Version |
|:---|:---|
| Flutter SDK | ≥ 3.10 |
| Dart SDK | ≥ 3.10 |
| Supabase Project | [Create one](https://supabase.com/) |
| Firebase Project | [Create one](https://console.firebase.google.com/) |

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/Dechawat-Wetprasit/mfu_fixflow.git
cd mfu_fixflow

# 2. Set up environment variables
cp .env.example .env
# Edit .env with your actual Supabase & Firebase credentials

# 3. Place Firebase config
# Download google-services.json from Firebase Console
# and place it in android/app/

# 4. Install dependencies
flutter pub get

# 5. Run the app
flutter run
```

### Environment Variables

| Variable | Description |
|:---|:---|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anonymous/public key |
| `FIREBASE_API_KEY_WEB` | Firebase Web API key |
| `FIREBASE_API_KEY_ANDROID` | Firebase Android API key |
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `FIREBASE_MESSAGING_SENDER_ID` | FCM sender ID |
| `FIREBASE_APP_ID_WEB` | Firebase Web app ID |
| `FIREBASE_APP_ID_ANDROID` | Firebase Android app ID |
| `FIREBASE_AUTH_DOMAIN` | Firebase auth domain |
| `FIREBASE_STORAGE_BUCKET` | Firebase storage bucket |
| `FIREBASE_MEASUREMENT_ID` | Firebase analytics measurement ID |

> 📌 See [`.env.example`](.env.example) for the full template.

---

## 👥 User Roles

| Role | Permissions |
|:---|:---|
| **Student** | Submit tickets, track status, receive notifications |
| **Manager** | View & manage tickets in assigned building |
| **Head Manager** | Oversee all buildings, assign work orders |
| **Technician** | Accept & resolve assigned repair tasks |
| **Head Technician** | Manage technician team and workload |
| **IT Admin** | Full system access, user management (CRUD) |

---

## 🔒 Security

- All sensitive credentials are loaded from `.env` at runtime via [`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv)
- Firebase config files (`google-services.json`, `firebase_options.dart`) are excluded from version control
- Supabase Edge Functions use server-side environment secrets
- Authentication uses PKCE flow for enhanced security

---

## 📄 License

This project was developed as part of a university project at **Mae Fah Luang University**.

---

<p align="center">
  <sub>Built with ❤️ using Flutter & Supabase</sub>
</p>
