# 🏗️ Windows Desktop Architecture

## 📐 System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      App Finanças v2.5.0                        │
│                    Windows Desktop Edition                      │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
        ┌───────────────────────────────────────┐
        │         main.dart (Entry Point)        │
        └───────────────────────────────────────┘
                                │
                                ▼
        ┌───────────────────────────────────────┐
        │    WidgetsFlutterBinding.initialize()  │
        └───────────────────────────────────────┘
                                │
                ┌───────────────┴───────────────┐
                ▼                               ▼
┌──────────────────────────┐    ┌──────────────────────────┐
│   _initWindow()          │    │ _initFirebaseIfSupported()│
│  - Check Platform        │    │  - Check Platform         │
│  - If Windows:           │    │  - If Android/iOS/Web:    │
│    • window_manager      │    │    • Firebase.init()      │
│    • Size: 1100x700      │    │  - If Windows/Linux/Mac:  │
│    • Min: 900x600        │    │    • Skip (offline mode)  │
└──────────────────────────┘    └──────────────────────────┘
                │                               │
                └───────────────┬───────────────┘
                                ▼
                    ┌───────────────────────┐
                    │    runApp(MyApp())    │
                    └───────────────────────┘
                                │
                                ▼
        ┌───────────────────────────────────────┐
        │        ChangeNotifierProvider          │
        │      (FinancasProvider State)          │
        └───────────────────────────────────────┘
                                │
                                ▼
        ┌───────────────────────────────────────┐
        │           MaterialApp                  │
        │       - Theme Configuration            │
        │       - Home: HomeScreen()             │
        └───────────────────────────────────────┘
```

## 🔄 Platform Detection Flow

```
                      ┌──────────────┐
                      │  App Start   │
                      └──────┬───────┘
                             │
                             ▼
                   ┌─────────────────┐
                   │ Check Platform  │
                   └────────┬────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│   Windows    │   │ Android/iOS  │   │     Web      │
└──────┬───────┘   └──────┬───────┘   └──────┬───────┘
       │                  │                   │
       ▼                  ▼                   ▼
  ┌─────────┐      ┌──────────┐       ┌──────────┐
  │ Window  │      │ Firebase │       │ Firebase │
  │ Manager │      │ Enabled  │       │ Enabled  │
  └─────────┘      └──────────┘       └──────────┘
       │                  │                   │
       ▼                  ▼                   ▼
  ┌─────────┐      ┌──────────┐       ┌──────────┐
  │ SQLite  │      │ SQLite + │       │ Firebase │
  │  Local  │      │ Firebase │       │ Firestore│
  └─────────┘      └──────────┘       └──────────┘
```

## 🗄️ Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ Dashboard│ │ Accounts │ │Transactions│ │ Reports  │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    State Management Layer                    │
│                   (Provider - FinancasProvider)              │
│  ┌────────────────────────────────────────────────────┐     │
│  │  • notifyListeners()                               │     │
│  │  • State synchronization                           │     │
│  │  • Business logic                                  │     │
│  └────────────────────────────────────────────────────┘     │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                     Service Layer                            │
│  ┌────────────────┐  ┌──────────────┐  ┌────────────────┐  │
│  │ DatabaseService│  │BackupService │  │  ExcelService  │  │
│  │   (SQLite)     │  │   (JSON)     │  │  (Export)      │  │
│  └────────────────┘  └──────────────┘  └────────────────┘  │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    Storage Layer                             │
│                                                              │
│  Windows:  C:\Users\[User]\AppData\Roaming\app_financas\   │
│  Android:  /data/data/com.example.app_financas/            │
│  iOS:      ~/Library/Application Support/                   │
│                                                              │
│  ┌──────────────────────────────────────────────────┐      │
│  │  app.db (SQLite)                                 │      │
│  │  - Accounts                                      │      │
│  │  - Transactions                                  │      │
│  │  - Categories                                    │      │
│  │  - Metas (Goals)                                │      │
│  │  - Remessas (Transfers)                         │      │
│  └──────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

## 🪟 Windows-Specific Components

```
┌─────────────────────────────────────────────────────────────┐
│                  Windows Desktop Features                    │
└─────────────────────────────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│   Window     │   │   SQLite     │   │   Path       │
│   Manager    │   │   Flutter    │   │   Provider   │
└──────────────┘   └──────────────┘   └──────────────┘
│                  │                  │
│  - Size control  │  - Local DB      │  - AppData    │
│  - Min/Max      │  - Transactions  │  - Documents  │
│  - Centering    │  - Offline mode  │  - Temp files │
│  - Focus        │  - Fast queries  │                │
└──────────────┘   └──────────────┘   └──────────────┘
```

## 📦 Build Pipeline

```
┌──────────────────┐
│  Source Code     │
│  (Dart/Flutter)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ flutter build    │
│   windows        │
│   --release      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│   C++ Compiler   │
│  (Visual Studio) │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│   Link DLLs      │
│  (Flutter +      │
│   Dependencies)  │
└────────┬─────────┘
         │
         ├─────────────────────┐
         ▼                     ▼
┌──────────────────┐  ┌──────────────────┐
│ .exe Executable  │  │  MSIX Package    │
│  (Portable)      │  │  (Installer)     │
└──────────────────┘  └──────────────────┘
         │                     │
         ▼                     ▼
┌──────────────────┐  ┌──────────────────┐
│  Release Folder  │  │  Microsoft Store │
│  (ZIP for dist)  │  │  (Future)        │
└──────────────────┘  └──────────────────┘
```

## 🔐 Security & Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      User Actions                            │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    Input Validation                          │
│  - Form validation                                           │
│  - Data type checking                                        │
│  - Range validation                                          │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                  Provider (State Management)                 │
│  - Business logic                                            │
│  - Data transformation                                       │
│  - State updates                                             │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    Database Service                          │
│  - SQL queries                                               │
│  - Transaction handling                                      │
│  - Data persistence                                          │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    SQLite (Local Storage)                    │
│  ✅ Encrypted on disk                                        │
│  ✅ No internet required                                     │
│  ✅ Fast local queries                                       │
│  ✅ Automatic backups available                              │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Deployment Options

```
                    ┌──────────────────┐
                    │   Build Complete │
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
      ┌──────────────┐ ┌──────────┐ ┌──────────────┐
      │   Portable   │ │   MSIX   │ │    Store     │
      │   (ZIP)      │ │ Installer│ │  (Future)    │
      └──────┬───────┘ └────┬─────┘ └──────┬───────┘
             │              │               │
             ▼              ▼               ▼
      ┌──────────────┐ ┌──────────┐ ┌──────────────┐
      │   Manual     │ │  Double  │ │  Automatic   │
      │  Extraction  │ │  Click   │ │   Updates    │
      └──────────────┘ └──────────┘ └──────────────┘
```

## 💡 Key Architectural Decisions

### 1. Platform-Aware Initialization
- ✅ Conditional imports based on platform
- ✅ Graceful degradation when features unavailable
- ✅ No runtime crashes from missing dependencies

### 2. Local-First Architecture
- ✅ SQLite as primary data store
- ✅ All operations work offline
- ✅ Optional cloud sync (via backup/restore)

### 3. Window Management
- ✅ Native window controls
- ✅ Persistent window state (future)
- ✅ Multi-monitor support

### 4. Build System
- ✅ Automated build scripts
- ✅ MSIX packaging support
- ✅ Easy distribution options

---

**This architecture ensures the app works seamlessly across all platforms while maintaining Windows-specific features!** 🎉
