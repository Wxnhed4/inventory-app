# KitchenStock Pro

`KitchenStock Pro` is a Flutter + Firebase mobile app for tracking kitchen inventory, production batches, and ingredient waste. In its current form, the project already supports basic inventory CRUD, waste logging, batch creation, and simple report views. For a final-year project, the best direction is to evolve it into a more polished food operations app for small restaurants, bakeries, cafes, and training kitchens.

This README does two jobs:

1. Documents what the project currently does.
2. Explains how to turn it into a stronger, presentation-ready final project.

---

## 1. Current Project Overview

### What the app currently does

The current app is an inventory management system connected to Firebase. It allows a user to:

- Sign in with Firebase Authentication using email and password
- Add, edit, and delete inventory items
- Record wasted ingredients and deduct them from stock
- Create production batches and deduct used ingredients from stock
- View batch history and waste history
- View simple report summaries from Firestore data

### Main features currently implemented

- Email/password login screen
- Firebase auth state gate
- Inventory list with add/edit/delete dialogs
- Waste recording form
- Waste history screen
- Batch creation form
- Batch history screen
- Reports screen with waste-by-ingredient and batch-usage summaries
- Drawer navigation across the main screens

### Technologies used

- `Flutter`
- `Dart`
- `Firebase Core`
- `Firebase Authentication`
- `Cloud Firestore`
- `Intl` for date formatting
- Material 3 widgets

### How to run the project

#### Prerequisites

- Flutter SDK installed
- A configured Firebase project
- Android Studio, VS Code, or another Flutter-compatible IDE
- A simulator, emulator, or physical device

#### Install dependencies

```bash
flutter pub get
```

#### Run the app

```bash
flutter run
```

#### Firebase setup note

This project already contains `lib/firebase_options.dart`, which means FlutterFire configuration was generated. However, `lib/main.dart` currently calls:

```dart
await Firebase.initializeApp();
```

For a stronger cross-platform setup, update it to:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

#### Authentication note

Right now, the app only includes a login screen. If you keep the current version unchanged, users must already exist in Firebase Authentication before they can sign in.

### Current project structure

| Path | Role |
| --- | --- |
| `lib/main.dart` | App entry point, Firebase initialization, routes, auth gate |
| `lib/firebase_options.dart` | Generated FlutterFire Firebase configuration |
| `lib/custom_drawer.dart` | Shared navigation drawer |
| `lib/screens/login_screen.dart` | Email/password sign-in UI |
| `lib/screens/inventory_screen.dart` | Inventory listing and CRUD dialogs |
| `lib/screens/waste_screen.dart` | Waste logging form and waste history |
| `lib/screens/batch_screen.dart` | Batch creation flow and batch history |
| `lib/screens/reports_screen.dart` | Simple reporting UI |
| `firestore.rules` | Firestore security rules |
| `storage.rules` | Firebase Storage rules |
| `test/widget_test.dart` | Default Flutter test template, currently outdated |

### Current screens and their purpose

| Screen | Purpose |
| --- | --- |
| `AuthGate` | Decides whether to open login or inventory based on Firebase auth state |
| `LoginScreen` | Allows the user to sign in with email and password |
| `InventoryScreen` | Shows all inventory items and allows add/edit/delete |
| `WasteScreen` | Records wasted stock and subtracts it from inventory |
| `WasteHistoryScreen` | Displays all recorded waste events |
| `BatchScreen` | Creates a production batch using inventory ingredients |
| `BatchHistoryScreen` | Displays all created batches and their ingredients |
| `ReportsScreen` | Shows summarized waste and batch usage data |

### How data flows in the app

The project currently follows a direct UI-to-Firebase approach:

`UI widget -> controller values -> simple validation in screen -> Firebase Auth / Firestore call -> Firestore stream or future -> UI rebuild`

Examples:

- Login flow:
  `LoginScreen -> FirebaseAuth.instance.signInWithEmailAndPassword() -> authStateChanges() -> AuthGate -> InventoryScreen`
- Inventory flow:
  `Inventory dialog -> Firestore collection('inventory').add/update/delete -> StreamBuilder -> Inventory list refresh`
- Waste flow:
  `Waste form -> add document to collection('waste') -> update inventory quantity -> reload inventory`
- Batch flow:
  `Batch form -> add document to collection('batches') -> decrement quantities in inventory -> reload inventory`

### Firebase collections currently used

#### `inventory`

Typical fields:

```json
{
  "name": "Flour",
  "quantity": 20,
  "unit": "kg"
}
```

#### `waste`

Typical fields:

```json
{
  "itemId": "inventoryDocId",
  "itemName": "Flour",
  "wastedQty": 2,
  "unit": "kg",
  "reason": "Spoiled",
  "chef": "Ali",
  "date": "2026-04-25",
  "timestamp": "server timestamp"
}
```

#### `batches`

Typical fields:

```json
{
  "batchName": "Cake Mix",
  "note": "Morning batch",
  "chef": "Sara",
  "date": "2026-04-25",
  "ingredients": [
    { "name": "Flour", "used": 5, "unit": "kg" }
  ],
  "timestamp": "server timestamp"
}
```

---

## 2. Current App Evaluation

### Missing features

- No user registration screen
- No logout confirmation or account/profile screen
- No onboarding or first-time app explanation
- No role-based permissions
- No dashboard or home summary screen
- No low-stock alerts
- No search, filter, sort, or category support
- No supplier, expiry-date, or purchase tracking
- No charts or visual analytics
- No settings screen
- No offline handling or loading/error states beyond basic cases
- No data export for presentation or management use

### UI/UX problems

- The interface is very plain and looks like a classroom prototype
- Most screens rely on basic forms and default Material widgets without a visual identity
- The login screen feels unfinished and tells the user to create accounts manually in Firebase Console
- The app starts directly into inventory instead of giving users a guided entry point
- There is no welcome flow, empty-state design, or summary experience
- Dialog-heavy CRUD feels functional but not modern
- Spacing, colors, buttons, and typography are inconsistent
- Reports are text-only and do not feel impressive for a final project demo
- Drawer navigation is serviceable but old-fashioned for a polished mobile app

### Code structure issues

- Business logic is mixed directly inside screen widgets
- Firebase calls are made directly from UI code
- No repository or service layer for Firestore/auth logic
- No models for inventory items, waste records, batches, or users
- No state management pattern such as `Provider`, `Riverpod`, `Bloc`, or `Cubit`
- Repeated styles and hard-coded colors are spread across files
- Navigation is route-based but not organized around feature modules
- Generated `firebase_options.dart` exists, but `main.dart` initializes Firebase without using `DefaultFirebaseOptions.currentPlatform`
- `test/widget_test.dart` is still the default Flutter counter test and does not test this app

### What makes it weak as a final project right now

- The app solves a useful problem, but the product story is not clearly defined
- The UX does not show strong mobile design thinking
- Authentication is incomplete because there is only login, no register/reset flow
- There is no onboarding, profile, settings, or personalization
- The architecture looks like an early prototype rather than a scalable app
- There are no polished demo screens such as dashboard, KPI cards, charts, notifications, or insights
- The current project can work as a base, but not yet as a strong showcase project

---

## 3. Final Project Direction

### Recommended purpose

Turn the app into a `Smart Kitchen Operations Manager`.

The final product should help small food businesses manage ingredients, reduce waste, monitor production, and make better daily decisions. This gives your app a stronger and more professional story than simply calling it an inventory app.

### Target users

- Small restaurants
- Bakeries
- Cafes
- Catering kitchens
- Culinary schools
- Kitchen managers and chefs

### Final version goal

The final version should help a kitchen team answer these questions quickly:

- What ingredients do we have right now?
- What items are running low?
- What was wasted today and why?
- Which batches used the most stock?
- How can we reduce waste and improve planning?

### Key features the final version should have

- Firebase authentication with login, register, logout, and password reset
- Onboarding screens that explain the app’s value and guide first setup
- Modern dashboard with inventory summary, waste summary, and batch activity
- Inventory management with categories, stock levels, and low-stock alerts
- Waste tracking with reasons, staff attribution, and insights
- Batch production tracking with ingredient consumption
- Reports with charts and time filters
- Profile/settings area
- Cleaner design system with reusable components and a consistent theme

---

## 4. Actionable Feature List

### Must-have features

These are the features you should build first to make the project strong enough for passing, presenting, and defending.

### 1. Authentication flow

**What it does**  
Adds real account creation and login using Firebase Auth.

**Why it improves the app**  
It makes the app feel like a real product instead of a demo. It also satisfies one of the main requirements for your final project.

**Files to create or modify**

- Modify `lib/main.dart`
- Replace or refactor `lib/screens/login_screen.dart`
- Create `lib/screens/register_screen.dart`
- Create `lib/screens/forgot_password_screen.dart`
- Create `lib/services/auth_service.dart`

**Suggested code snippet**

```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
```

### 2. Onboarding screens

**What it does**  
Shows 2 to 3 intro screens the first time the app opens, explaining inventory control, waste tracking, and reporting benefits.

**Why it improves the app**  
It gives the app a professional first impression and helps define its purpose clearly during your presentation.

**Files to create or modify**

- Create `lib/screens/onboarding_screen.dart`
- Create `lib/models/onboarding_page_model.dart`
- Modify `lib/main.dart`
- Add local persistence later with `shared_preferences`

**Suggested code snippet**

```dart
final pages = [
  {
    'title': 'Track Stock Clearly',
    'subtitle': 'See ingredient quantities and low-stock items in one place.',
  },
  {
    'title': 'Reduce Kitchen Waste',
    'subtitle': 'Log spoilage and discover the biggest waste causes.',
  },
  {
    'title': 'Plan Better Batches',
    'subtitle': 'Record ingredient usage and improve production decisions.',
  },
];
```

### 3. Dashboard / home screen

**What it does**  
Adds a central landing screen after login with summary cards, recent activity, and quick actions.

**Why it improves the app**  
This immediately makes the app feel more complete, modern, and impressive during a demo.

**Files to create or modify**

- Create `lib/screens/dashboard_screen.dart`
- Modify `lib/custom_drawer.dart`
- Modify `lib/main.dart`
- Create `lib/widgets/summary_card.dart`
- Create `lib/services/dashboard_service.dart`

**Suggested code snippet**

```dart
class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(value),
        subtitle: Text(title),
      ),
    );
  }
}
```

### 4. Better app structure

**What it does**  
Moves Firebase logic out of screens and into services/repositories/models.

**Why it improves the app**  
This makes the code easier to maintain, easier to explain to your supervisor, and more professional.

**Files to create or modify**

- Create `lib/models/inventory_item.dart`
- Create `lib/models/waste_record.dart`
- Create `lib/models/batch_record.dart`
- Create `lib/services/inventory_service.dart`
- Create `lib/services/waste_service.dart`
- Create `lib/services/batch_service.dart`
- Refactor existing screen files to use these services

**Suggested code snippet**

```dart
class InventoryItem {
  final String id;
  final String name;
  final int quantity;
  final String unit;

  InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory InventoryItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryItem(
      id: doc.id,
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 0,
      unit: data['unit'] ?? '',
    );
  }
}
```

### 5. Inventory improvements

**What it does**  
Adds category, minimum stock, supplier, expiry date, and search/filter support.

**Why it improves the app**  
It turns the inventory page into a real management tool instead of just a simple list.

**Files to create or modify**

- Modify `lib/screens/inventory_screen.dart`
- Create `lib/widgets/inventory_item_card.dart`
- Create `lib/widgets/inventory_filter_bar.dart`
- Update Firestore inventory document structure

**Suggested code snippet**

```dart
await _items.add({
  'name': name,
  'quantity': qty,
  'unit': unit,
  'category': category,
  'minStock': minStock,
  'supplier': supplier,
  'expiryDate': expiryDate,
  'createdAt': FieldValue.serverTimestamp(),
});
```

### 6. Modern UI theme

**What it does**  
Creates a consistent design system with brand colors, typography, cards, buttons, spacing, and input styles.

**Why it improves the app**  
Visual quality matters a lot in final project grading. A cohesive UI makes the whole app feel more advanced.

**Files to create or modify**

- Create `lib/core/theme/app_theme.dart`
- Create `lib/core/theme/app_colors.dart`
- Modify `lib/main.dart`
- Update all screen files to use the new theme

**Suggested code snippet**

```dart
final theme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF0F766E),
  ),
  scaffoldBackgroundColor: const Color(0xFFF6F8F7),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
);
```

### 7. Reports with charts

**What it does**  
Turns the reports page into a visual analytics screen using bar charts, pie charts, and time filters.

**Why it improves the app**  
Charts make the project look much more complete and easier to present.

**Files to create or modify**

- Modify `lib/screens/reports_screen.dart`
- Add a chart package such as `fl_chart`
- Create `lib/widgets/report_chart_card.dart`

**Suggested code snippet**

```dart
final spots = [
  FlSpot(0, 4),
  FlSpot(1, 7),
  FlSpot(2, 3),
];
```

### 8. Proper Firebase initialization

**What it does**  
Uses generated FlutterFire configuration correctly on every platform.

**Why it improves the app**  
It avoids configuration issues and makes the app look technically solid.

**Files to create or modify**

- Modify `lib/main.dart`

**Suggested code snippet**

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Nice-to-have features

These features can improve your grade and make the project stand out.

### 1. User profile and role system

**What it does**  
Adds kitchen manager and staff roles with different permissions.

**Why it improves the app**  
Shows deeper system design and makes the app more realistic.

**Files to create or modify**

- Create `lib/models/app_user.dart`
- Create `lib/screens/profile_screen.dart`
- Create `lib/services/user_service.dart`
- Update Firestore rules

### 2. Notifications and low-stock alerts

**What it does**  
Highlights items below minimum stock and shows reminders on the dashboard.

**Why it improves the app**  
Makes the app proactive, not just reactive.

**Files to create or modify**

- Modify `lib/screens/dashboard_screen.dart`
- Modify `lib/screens/inventory_screen.dart`
- Create `lib/widgets/low_stock_banner.dart`

### 3. Export reports

**What it does**  
Exports analytics or inventory summaries as PDF or CSV.

**Why it improves the app**  
This is useful in real business workflows and looks strong in a viva/presentation.

**Files to create or modify**

- Create `lib/services/export_service.dart`
- Create `lib/screens/export_screen.dart`

### 4. Search, filter, and date range across all modules

**What it does**  
Improves discoverability and record review in inventory, batches, waste, and reports.

**Why it improves the app**  
Makes the app much easier to use with larger data sets.

**Files to create or modify**

- Modify `lib/screens/inventory_screen.dart`
- Modify `lib/screens/waste_screen.dart`
- Modify `lib/screens/batch_screen.dart`
- Modify `lib/screens/reports_screen.dart`

### 5. Empty states and success states

**What it does**  
Adds polished placeholders when there is no data and clear confirmation after actions.

**Why it improves the app**  
This makes the app feel intentional and user-friendly instead of raw.

**Files to create or modify**

- Create `lib/widgets/empty_state_view.dart`
- Create `lib/widgets/success_banner.dart`
- Update all existing screens

### 6. Dark mode or theme switching

**What it does**  
Lets the user switch themes or follow system appearance.

**Why it improves the app**  
Shows UI maturity and attention to personalization.

**Files to create or modify**

- Modify `lib/core/theme/app_theme.dart`
- Create `lib/services/theme_service.dart`
- Create `lib/screens/settings_screen.dart`

### 7. Image attachments for waste or inventory

**What it does**  
Allows attaching images of spoiled items or stored ingredients.

**Why it improves the app**  
Adds realism and uses more of Firebase, especially Storage.

**Files to create or modify**

- Add `firebase_storage`
- Create `lib/services/storage_service.dart`
- Modify `lib/screens/waste_screen.dart`
- Modify `lib/screens/inventory_screen.dart`

### 8. Better testing

**What it does**  
Replaces the default sample test with real widget/service tests.

**Why it improves the app**  
Shows engineering quality and makes the project easier to trust.

**Files to create or modify**

- Replace `test/widget_test.dart`
- Add `test/services/auth_service_test.dart`
- Add `test/widgets/login_screen_test.dart`

---

## 5. Recommended UI/UX Direction

### Design style

Use a clean, modern operations dashboard style:

- Primary color: `#0F766E` (teal)
- Secondary accent: `#F59E0B` (amber) for alerts and waste indicators
- Background: `#F6F8F7`
- Surface cards: white with soft shadows
- Error color: `#DC2626`
- Rounded corners: `14` to `18`
- Large spacing and clear section blocks
- Bold page headers with supportive subtitle text
- Use cards for KPIs, recent activity, and quick actions

### Typography and components

- Use one consistent font such as `Poppins`, `Manrope`, or `Plus Jakarta Sans`
- Use larger headline text on dashboard and onboarding screens
- Use medium-weight labels and readable form fields
- Prefer segmented summaries, cards, chips, and bottom sheets over plain dialogs
- Replace long plain lists with grouped cards and badges

### How to redesign existing screens

#### Login screen

- Add a welcome headline and short product value message
- Add login + register toggle or separate register screen
- Add password reset link
- Add cleaner spacing, stronger branding, and a hero illustration/icon area

#### Inventory screen

- Add summary cards at the top:
  `Total items`, `Low stock`, `Categories`
- Replace plain `ListTile` rows with cards showing stock badge and category
- Add search field and filter chips
- Move add-item flow into a polished modal bottom sheet

#### Waste screen

- Show recent waste summary at the top
- Use better labels and grouped form sections
- Add reason chips instead of plain dropdown only
- Show recent waste records below the form

#### Batch screen

- Break the form into sections:
  `Batch details`, `Ingredients`, `Notes`
- Use a cleaner ingredient selector instead of one long raw list
- Add a preview section showing total ingredients used before submit

#### Reports screen

- Replace text-only results with charts and KPI cards
- Add tabs such as `Today`, `This Week`, `This Month`
- Show top wasted item, most used item, and waste trend

### New screens to add

- `DashboardScreen`
- `OnboardingScreen`
- `RegisterScreen`
- `ForgotPasswordScreen`
- `ProfileScreen`
- `SettingsScreen`
- `InventoryDetailsScreen`
- `LowStockScreen`
- `InsightsScreen`

---

## 6. Recommended Refactored Folder Structure

This structure will make the project cleaner and easier to explain:

```text
lib/
  core/
    theme/
      app_colors.dart
      app_theme.dart
    utils/
      validators.dart
  models/
    inventory_item.dart
    waste_record.dart
    batch_record.dart
    app_user.dart
  services/
    auth_service.dart
    inventory_service.dart
    waste_service.dart
    batch_service.dart
    dashboard_service.dart
  widgets/
    custom_drawer.dart
    summary_card.dart
    inventory_item_card.dart
    empty_state_view.dart
  screens/
    onboarding_screen.dart
    login_screen.dart
    register_screen.dart
    forgot_password_screen.dart
    dashboard_screen.dart
    inventory_screen.dart
    waste_screen.dart
    batch_screen.dart
    reports_screen.dart
    profile_screen.dart
    settings_screen.dart
  main.dart
```

---

## 7. Practical Roadmap

### Phase 1

- Fix Firebase initialization
- Add register screen
- Add forgot password screen
- Create onboarding flow
- Build dashboard screen
- Add reusable theme system

### Phase 2

- Refactor Firestore and auth logic into services
- Create data models
- Improve inventory screen with search, categories, and stock alerts
- Improve batch and waste screens

### Phase 3

- Add charts and better reports
- Add profile and settings
- Add export features
- Add testing

---

## 8. Final Recommendation

This project already has a useful foundation. The strongest final-project version is not to abandon the idea, but to present it as a polished `smart kitchen management app` focused on:

- inventory control
- waste reduction
- batch production tracking
- operational insights

If you add authentication, onboarding, a dashboard, cleaner architecture, and a more modern UI, this can become a very credible final project with both technical and practical value.
