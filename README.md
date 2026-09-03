# Stylorista-AI

Stylorista-AI is a privacy-conscious fashion styling MVP built with Flutter and a FastAPI/scikit-learn service. It combines:

- a fashion-led sign-in experience with a one-time welcome screen;
- guided fashion measurements and a starting-size recommendation;
- a consent-gated camera or photo scan that estimates 11 garment measurements after one height calibration;
- an AI-fit shopping feed with live Shopee and Lazada search links;
- a category-filtered fashion news feed powered by Google News RSS and GDELT, with optional approved Reddit OAuth access;
- a four-season personal-color direction from selected skin, hair, and eye colors;
- climate- and season-aware outfit recommendations;
- explicit explanations and limitations for every AI result.

> **Prototype status:** The included models train on deterministic synthetic reference data. They prove the product and technical workflow, but they are not validated for commercial sizing, biometric measurement, or purchasing guarantees.

> **Authentication status:** The sign-in screen is a local UI demonstration. It saves only the signed-in and welcome-completed flags on the device so returning users can open Home directly. It never saves email or password values, does not contact an identity service, and does not establish a secure production session.

## Repository structure

```text
lib/                 Flutter user interface
backend/app/         FastAPI routes, schemas, and scikit-learn engine
backend/tests/       API tests
docs/PRODUCT_PLAN.md Product definition and delivery roadmap
docs/AUDIT.md        Brand, product, privacy, AI, and technical audit
```

## Run the Python API

Create a virtual environment and install the dependencies:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --reload
```

The API is served at `http://127.0.0.1:8000`; interactive documentation is at `http://127.0.0.1:8000/docs`.

The fashion feed reads Google News RSS and GDELT without a local key. Optional Reddit stories require approved Reddit Data API access and an OAuth token:

```powershell
$env:REDDIT_ACCESS_TOKEN="your-approved-oauth-token"
```

Facebook and Instagram are shown as unavailable until an approved Meta app and eligible accounts are connected; the prototype does not scrape private or restricted social feeds.

## Run Flutter

From the repository root:

```powershell
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

For an Android emulator, point the app at the host loopback alias:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## Verify

```powershell
flutter analyze
flutter test
cd backend
python -m pytest
```

## Privacy boundary

The body-scan prototype sends a selected photo to the configured API only after an explicit consent checkbox. The API decodes and analyzes it in memory and does not include storage or training reuse. Measurements and selected color values are sent only when the user starts their respective analysis.

The camera estimator needs a known height because an ordinary single photo has no absolute centimetre scale. It is trained on synthetic proportions and is not validated for purchasing, tailoring, biometric identification, or medical use. Continuous measurement quality must be evaluated with centimetre error and within-tolerance rates; a 98% ROC-AUC claim would be technically inappropriate and is not made.

## Important naming note

`Stylorista-AI` is a working product name, not a cleared trademark. An initial web check found the exact word “Stylorista” in an existing public fashion-name list. Obtain professional trademark, company-registry, app-store, social-handle, and domain clearance before public launch.
