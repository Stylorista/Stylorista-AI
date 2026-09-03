# Stylorista-AI

Stylorista-AI is a privacy-conscious fashion styling MVP built with Flutter and FastAPI. It combines:

- database-backed registration, hashed passwords, 30-day session tokens, and a one-time welcome screen;
- guided fashion measurements and a starting-size recommendation;
- a consent-gated camera or photo scan that estimates 11 garment measurements using the height saved during registration;
- an AI-fit shopping feed with live Shopee, Lazada, and Temu search links;
- a category-filtered fashion news feed powered by publisher RSS, Google News, and GDELT, with article-owned Open Graph imagery and duplicate-image removal;
- a curated profile hub with fit scanning, weather-aware outfits, complexion color guidance, and consent-based accessory suggestions;
- live current and next-day city weather with forecast-matched fashion guidance;
- a four-season personal-color direction from selected skin, hair, and eye colors;
- climate- and season-aware outfit recommendations;
- explicit explanations and limitations for every AI result.

> **Prototype status:** The body scanner uses deterministic image geometry and strict full-person/framing checks. It proves the product workflow, but it is not validated for commercial sizing, tailoring, biometric measurement, or purchasing guarantees.

> **Authentication status:** Accounts are validated by the API. Passwords are stored as salted PBKDF2-SHA256 hashes, raw passwords are never retained, and accepted measurement profiles can be restored after sign-in. Local development uses SQLite; hosted deployments should configure PostgreSQL for durable storage.

## Repository structure

```text
lib/                 Flutter user interface
backend/app/         FastAPI routes, account storage, news, weather, and analysis engines
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

Publisher and GDELT images are taken from the story metadata. When a feed omits an image, the API attempts to read `og:image` or `twitter:image` from the article itself. It never substitutes the same local fashion photo across unrelated stories.

Home weather uses Open-Meteo city search and its current/two-day forecast. Manila is the default, and users can enter another city without granting precise device-location permission.

### Account database

For local use, the API creates `backend/data/stylorista.db` automatically. For an online Render deployment, create a Render PostgreSQL database and set the web service's `DATABASE_URL` environment variable to its internal connection string. The app will switch to PostgreSQL automatically. Render's free PostgreSQL databases currently expire after 30 days, so use a paid database or another durable PostgreSQL provider before real users rely on the service.

The marketplace cards deliberately do not copy or scrape listing photos. Their buttons open current results on Shopee, Lazada, and Temu. Showing individual product images, prices, and stock inside the app requires approved marketplace seller or affiliate API credentials.

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

The body-scan and profile-accessory prototypes send a selected photo to the configured API only after an explicit consent checkbox. The API decodes and analyzes it in memory and does not include photo storage or training reuse. Only a scan that passes the person, framing, and confidence checks can update the signed-in account's measurement profile.

The camera estimator needs a known height because an ordinary single photo has no absolute centimetre scale. That height is collected once during account creation and reused silently for scans. The estimator is not validated for purchasing, tailoring, biometric identification, or medical use. Continuous measurement quality must be evaluated against consented ground-truth tape measurements using centimetre error and within-tolerance rates; a 98% ROC-AUC claim would be technically inappropriate and is not made.

## Important naming note

`Stylorista-AI` is a working product name, not a cleared trademark. An initial web check found the exact word “Stylorista” in an existing public fashion-name list. Obtain professional trademark, company-registry, app-store, social-handle, and domain clearance before public launch.
