# EventPass - Campus Student Access & Event Management System

**EventPass** is an end-to-end event management, digital ticketing, and QR code access control platform built for university campuses and student activity organizations. 

The system unifies a cross-platform **Flutter mobile application** for students and event coordinators, a high-performance **ASP.NET Core REST API**, and a dedicated **Admin Management Web Portal** featuring Category-Based Role-Based Access Control (RBAC).

---

## 🌟 Architecture Overview

```
                      ┌───────────────────────────────────────┐
                      │          Flutter Mobile App           │
                      │  (Students & Mobile Gate Check-in)    │
                      └──────────────────┬────────────────────┘
                                         │  HTTPS / JWT
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       ASP.NET Core Unified Backend                          │
│                                                                             │
│   ┌───────────────────────────┐             ┌───────────────────────────┐   │
│   │     Mobile REST APIs      │             │     Admin Web Portal      │   │
│   │    /api/auth, /api/events │             │    /Portal (Razor / MVC)  │   │
│   │  /api/registrations, etc. │             │  Admins, Metrics, Events  │   │
│   └─────────────┬─────────────┘             └─────────────┬─────────────┘   │
│                 │                                         │                 │
│                 └────────────────────┬────────────────────┘                 │
│                                      ▼                                      │
│                         Entity Framework Core 10                            │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
                       PostgreSQL (Neon) / SQLite DB
```

---

## 🚀 Key Features

### 1. 📱 Mobile Application (Flutter)
- **Student Experience**:
  - Browse active upcoming university events across categories.
  - One-tap event registration generating unique secure QR entry tokens.
  - **My Pass**: Offline-capable digital ticket display with dynamic branding and status.
- **Mobile Gate Scanner**:
  - Built-in camera scanner for gate admins to quickly validate student QR passes.
  - Immediate check-in verification with real-time feedback (Success, Already Used, Invalid Token).
- **Category-Aware Admin Views**:
  - SuperAdmins have access to all events and global event controls.
  - Category Admins automatically view only the events and attendees within their authorized activity domain (e.g., Music & Arts, Hackathons & Coding).

### 2. 🌐 Admin Web Portal (`/Portal`)
- **SuperAdmin Management Dashboard**:
  - Key performance metrics: total active events, student registrations, and verified check-ins.
  - Create and delegate department/activity admins with scoped categories.
  - Category CRUD management (color badges, icons, descriptions).
- **Category-Scoped Administration**:
  - Department admins (e.g., Music Admin) only access and manage events belonging to their assigned activity.
  - Real-time attendee logs with search, registration timestamps, check-in history, and pass revocation.
- **Dual Authentication Architecture**:
  - Cookie-based session authentication for desktop web browser navigation.
  - Stateless JWT Bearer tokens for mobile app APIs.

### 3. ⚙️ Robust Backend (.NET 10 & EF Core)
- Built with **ASP.NET Core** and **Entity Framework Core**.
- PostgreSQL (Neon Cloud) support with automatic incremental schema migrations on container boot.
- UTC DateTime normalization ensuring PostgreSQL compatibility.
- Interactive OpenAPI / Swagger UI at `/swagger`.

---

## 📂 Project Structure

```
Student-Access/
├── .gitignore                          # Git ignore rules for .NET, Flutter, and OS files
├── Dockerfile                          # Multi-stage production container for Render deployment
├── swagger.html                        # Standalone API documentation portal
├── Backend/
│   ├── docker-compose.yml              # Local container orchestration
│   ├── StudentAccess.slnx              # Visual Studio solution file
│   └── StudentAccess/
│       ├── Controllers/                # REST API controllers & PortalController
│       ├── Data/                       # EF Core DbContext & DbInitializer
│       ├── Dtos/                       # Data Transfer Objects (Auth, Events, Registrations)
│       ├── Models/                     # Database entities (User, Event, Category, Registration)
│       ├── Services/                   # Business logic (AuthService, EventService, ScannerService)
│       ├── Views/                      # Razor Views for the Web Portal (/Portal)
│       ├── wwwroot/                    # Web portal static assets (CSS, JS)
│       └── Program.cs                  # Dependency injection & middleware pipeline
└── Frontend/
    ├── assets/                         # Lottie animations and icons
    ├── lib/
    │   ├── Models/                     # Dart models (EventItem, UserProfile, PassData)
    │   ├── Screens/                    # Flutter UI screens (Auth, Event List, Details, Scanner, Pass)
    │   ├── Services/                   # HTTP client API services
    │   ├── Widgets/                    # Reusable UI widgets and form components
    │   └── main.dart                   # Flutter application entry point
    ├── android/, ios/, macos/, windows/, web/  # Multi-platform native runners
    └── pubspec.yaml                    # Flutter dependencies and assets configuration
```

---

## 🛠️ Getting Started

### Prerequisites
- [.NET 10 SDK](https://dotnet.microsoft.com/)
- [Flutter SDK (v3.x+)](https://flutter.dev/)
- [PostgreSQL](https://www.postgresql.org/) (or use the built-in SQLite fallback for development)

---

### Backend Setup

1. **Navigate to the Backend directory**:
   ```bash
   cd Backend/StudentAccess
   ```

2. **Configure Database Connection**:
   Update `appsettings.json` or set the `ConnectionStrings__DefaultConnection` environment variable:
   ```json
   {
     "ConnectionStrings": {
       "DefaultConnection": "Host=your-postgres-host;Database=eventpass;Username=your-user;Password=your-pass;"
     }
   }
   ```

3. **Run the Backend**:
   ```bash
   dotnet run
   ```
   - Web Portal: `http://localhost:<port>/Portal`
   - Swagger Explorer: `http://localhost:<port>/swagger`

---

### Frontend Setup

1. **Navigate to the Frontend directory**:
   ```bash
   cd Frontend
   ```

2. **Install Flutter Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure API Base URL**:
   In the mobile app, tap the Ethernet / Settings icon on the top right of the event list screen to configure the server IP, or update `lib/Services/api_config.dart`.

4. **Launch Flutter**:
   ```bash
   flutter run
   ```

---

## 👥 Default Seeded Accounts

When the backend initializes for the first time, it automatically provisions the following default roles and categories:

| Role | Email | Password | Scope |
| :--- | :--- | :--- | :--- |
| **SuperAdmin** | `admin@eventpass.com` | `AdminPassword123!` | Full global control across all categories, admins, events, and metrics. |
| **Music Admin** | `music.admin@eventpass.com` | `MusicAdmin123!` | Scoped exclusively to *Music & Arts* events and attendees. |
| **Hackathon Admin** | `hackathon.admin@eventpass.com` | `HackathonAdmin123!` | Scoped exclusively to *Hackathons & Coding* events and attendees. |

---

## 🚢 Deployment

The repository includes a production-ready [`Dockerfile`](file:///C:/Users/ahmed/source/repos/AhmedHanyMohammed/Student-Access/Dockerfile) configured for [Render](https://render.com) or any containerized cloud platform. Render automatically binds to the `$PORT` environment variable and launches the unified backend and web portal.
