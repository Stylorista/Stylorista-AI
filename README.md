# Stylorista-AI

Stylorista-AI is a privacy-conscious fashion styling MVP built with Flutter and a FastAPI/scikit-learn service. It combines:

- guided fashion measurements and a starting-size recommendation;
- a four-season personal-color direction from selected skin, hair, and eye colors;
- climate- and season-aware outfit recommendations;
- explicit explanations and limitations for every AI result.

> **Prototype status:** The included models train on deterministic synthetic reference data. They prove the product and technical workflow, but they are not validated for commercial sizing, biometric measurement, or purchasing guarantees.

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

The MVP does not upload photographs. It sends only the measurements and color values that a user actively selects. A future camera-based body scanner requires a separate consent flow, on-device preprocessing where possible, retention controls, calibrated capture, bias testing, and validation against professional measurements.

## Important naming note

`Stylorista-AI` is a working product name, not a cleared trademark. An initial web check found the exact word “Stylorista” in an existing public fashion-name list. Obtain professional trademark, company-registry, app-store, social-handle, and domain clearance before public launch.

