# CASEYA — Dairy Plant Calculation & Operations Management System

> **Dairy Plant Operations & Calculation System**  
> A production-ready, industrial dairy management and mathematical calculation web application engineered for plant operators, shift supervisors, and quality technologists.

---

## 🥛 1. Overview & Architecture

**CASEYA** is built using **Clean Architecture** principles in **Flutter Web** with **Riverpod** for robust reactive state management, backed by a **FastAPI** service layer with a **Google Sheets** initial datastore and seamless migration readiness to PostgreSQL/Supabase.

### 🛡️ Security Architecture
- **Zero Frontend Secrets:** No Google API credentials, service account JSON files, or private backend tokens exist in the Flutter Web client bundle.
- **Client Resilience:** Works 100% offline out-of-the-box via persistent browser storage (`SharedPreferences`), automatically syncing with FastAPI and Google Sheets when backend connections are enabled in Settings.

```text
lib/
├── core/
│   ├── constants/       # AppColors (Dairy Green), AppConstants, AppStrings
│   ├── theme/           # Minimalist Industrial Dairy Material 3 theme
│   ├── utils/           # Number & Date Formatters, ResponsiveLayout
│   ├── validators/      # Strict numeric, percentage, and level validators
│   └── widgets/         # AppCard, AppHeader, AppSidebar, ResultCard,
│                        # CalculationBreakdown, SearchableDropdown, etc.
│
├── models/              # ProductModel, BoilerRecord, StandardizationRecord,
│                        # LabRecord, UserModel, ProductionRecord, StockRecord
│
├── services/            # CalculationService, BoilerCalculator,
│                        # MilkStandardizationCalculator, LocalStorageService,
│                        # ApiService, GoogleSheetsSchema
│
├── repositories/        # ProductRepository, BoilerRepository,
│                        # StandardizationRepository, LabRepository, OperationsRepository
│
├── providers/           # Riverpod state notifiers: Auth, ProductCalculator,
│                        # Standardization, Boiler, Dashboard, ProductsMaster
│
├── pages/
│   ├── shell/           # MainShellPage (Responsive desktop + mobile navigation)
│   ├── dashboard/       # Plant overview, KPIs, and recent activity timeline
│   ├── product_calculator/   # Dynamic pieces/crates/volume conversions
│   ├── milk_standardization/ # QC lab data fetch & modular standardization
│   ├── boiler/          # Calibrated fuel consumption with top-up options
│   ├── production/      # Daily pasteurization and packaging floor outputs
│   ├── dispatch/        # Cold-chain vehicle departure logs and routes
│   ├── packaging/       # Pouch machine roll counts and wastage metrics
│   ├── stock/           # Cold room inventory balances and threshold alerts
│   ├── reports/         # Date-range reports with CSV & printable exports
│   ├── products_master/ # Product catalog & target standards management
│   └── settings/        # Role switcher, formula options, and backend URL
│
└── main.dart            # ProviderScope entry point with storage initialization
```

---

## 🎨 2. Design System

- **Brand:** **CASEYA**
- **Subtitle:** Dairy Plant Operations & Calculation System
- **Colors:**
  - Primary Industrial Dairy Green: `#1B5E3A`
  - Mint Container Accent: `#E8F5E9`
  - Crisp Neutral Surface: `#FFFFFF`
  - Border Contrast: `#E2E8E4`
  - Clean Background: `#F7FAF8`
- **Ergonomics:** Large readable typography, high-contrast numeric metric cards, zero visual clutter, touch-friendly (>48px) mobile controls.

---

## 🧮 3. Core Calculation Modules

### A. Product Calculator
- **Searchable Product Master:** Select from plant products (e.g. *Purabi Plus Milk 500 ml*, *Curd Pouch 400 g*, *Lassi 200 ml*).
- **Product Metadata Card:** Displays Category, Pack Size, Base Unit, Pieces per Crate, and Target Standards.
- **Dynamic Input Modes:** Automatically displays only allowed modes based on product type:
  - Milk: `[Pieces, Crates, Litres]`
  - Curd: `[Pieces, Crates, Kg]`
- **Calculation Output:**
  - $\text{Pieces} = \text{Entered Quantity}$ (or derived)
  - $\text{Crates} = \frac{\text{Pieces}}{\text{Pieces Per Crate}}$
  - $\text{Volume} = \text{Pieces} \times \text{Pack Size}$
- **Collapsible Breakdown:** Step-by-step mathematical verification.
- **Audit Persistence:** Saves calculation records to historical log.

### B. Milk Standardization Calculator
- **Inputs:** Date, Milk Quantity (L), Milk FAT %, Milk SNF %.
- **Fetch Today's QC Lab Data:** 
  - One-click retrieval of morning laboratory silo/tanker samples.
  - Automatically loads Milk Quantity, tested FAT %, and tested SNF %.
  - Prompts confirmation before overwriting operator inputs.
- **Target Product Specifications:** Standard FAT and SNF targets loaded dynamically from Product Master.
- **Modular Formula Engine:** Designed so plant-specific formulas can be inserted directly into `lib/services/milk_standardization_calculator.dart` between `[PLANT_STANDARDIZATION_FORMULA_START]` and `[PLANT_STANDARDIZATION_FORMULA_END]`.
- **Outputs:**
  - Water Required (Dilution)
  - Skimmed Milk Powder (SMP) Required (SNF boosting)
  - Sugar Required (for sweetened recipes like Curd/Lassi)
  - Final Quantity, Final FAT %, Final SNF %
- **Audit Persistence:** Full date-wise batch record archiving.

### C. Boiler Fuel Consumption
- **Inputs:** Date, Shift (Shift A, B, C, General), Opening CM, Closing CM, Running Hours, Fuel Top-up (L), Remarks.
- **Calibrated Formula:**
  $$\text{Fuel Consumption (L)} = \frac{(\text{Opening CM} - \text{Closing CM}) \times 900}{70}$$
- **Configurable Top-up Logic:**
  - Supports separate tracking of `calculatedLevelConsumption`, `fuelTopUp`, and `netReportedConsumption`.
  - Configurable toggle in UI & Settings: *Include Top-up in Net Shift Consumption*.
- **Consumption Per Hour:**
  $$\text{Consumption / Hour} = \frac{\text{Net Consumption}}{\text{Running Hours}}$$
  *(Protected against division by zero)*.
- **Date-wise Records Table:** Search, date filter, shift filter, edit, view, and deletion with confirmation dialog.

---

## 🧪 4. Unit Test Verification

To execute the test suite:
```bash
flutter test
```

Includes unit tests verifying:
1. Standard plant boiler formula (500 CM $\to$ 430 CM $= 900\text{ L}$, 8.5 hrs $= 105.88\text{ L/hr}$).
2. Boiler top-up inclusion and exclusion modes.
3. Boiler division by zero protection when running hours is 0.
4. Product conversion across Pieces, Crates, Litres, and Kg for multiple products.
5. Milk standardization mass balance calculations.
6. Responsive widget launch and component smoke tests.

---

## 🚀 5. How to Run Locally

### Running Flutter Web Frontend
```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run locally in Chrome / Edge
flutter run -d chrome
```

### Running FastAPI Backend
```bash
# 1. Navigate to backend directory
cd backend

# 2. Create and activate a virtual environment
python -m venv venv
venv\Scripts\activate  # Windows

# 3. Install requirements
pip install -r requirements.txt

# 4. Start API server
uvicorn main:app --reload --port 8000
```
Interactive API documentation will be available at `http://localhost:8000/docs`.

---

## 📊 6. Google Sheets Integration Architecture

To use Google Sheets as the operational datastore:
1. Create a Google Cloud Project and enable the **Google Sheets API** and **Google Drive API**.
2. Create a Service Account and download the JSON key.
3. Save the key on the backend at `backend/credentials/service_account.json` (NEVER in Flutter code).
4. Share your Google Sheet with the service account client email with *Editor* permissions.
5. In `backend/.env`, set:
   ```env
   GOOGLE_SHEETS_SPREADSHEET_ID=your_sheet_id_here
   GOOGLE_SERVICE_ACCOUNT_FILE=credentials/service_account.json
   ```

Sheets Schema:
- `Users`
- `Products`
- `Lab_Data`
- `Standardization`
- `Boiler`
- `Production`
- `Dispatch`
- `Packaging`
- `Stock`
- `Audit_Log`

---

## 🌐 7. Deploying to Vercel

The repository is configured for one-click Vercel deployment with `vercel.json`:

```bash
# 1. Build release web bundle locally
flutter build web --release

# 2. Deploy with Vercel CLI (or connect GitHub repository)
vercel --prod
```

Or connect the GitHub repo to Vercel and set:
- **Framework Preset:** Other
- **Build Command:** `flutter/bin/flutter build web --release`
- **Output Directory:** `build/web`

---

## 👥 8. User Roles & Access Control

- **Admin:** Manage products, configure formulas, manage users, edit/delete all historical records.
- **Supervisor:** Enter daily operational logs, edit shift records, view calculations and analytics reports.
- **Operator:** Perform product and standardization calculations, log shift boiler and production entries.

---

## 📄 License
Internal Dairy Plant Operations System. All rights reserved.
