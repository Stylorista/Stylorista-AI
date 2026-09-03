# Stylorista-AI initial audit

Audit date: 2026-08-29  
Scope: working brand, MVP product concept, AI validity, privacy, safety, accessibility, and technical implementation.

## Executive assessment

The concept is viable as a guided styling assistant. Its strongest differentiation is the combination of body measurements, personal color, and local climate—including tropical wet/dry seasons—inside one explained profile.

The largest product risk is overclaiming. A photo does not yield trustworthy absolute body measurements without calibration, controlled capture, computer vision, validation, and robust handling of pose and clothing. The MVP now includes an explicitly experimental, height-calibrated silhouette scan alongside guided tape measurements. Its generated-data models are appropriate for demonstrating system flow only.

## Brand-name audit

| Check | Result | Risk | Required action |
|---|---|---:|---|
| Exact web phrase “Stylorista-AI” | No obvious operating product found in the initial search | Medium | Repeat across markets and languages before launch |
| Word “Stylorista” | Appears in a public personal-stylist name list | Medium | Do not claim inherent uniqueness |
| Trademark registers | Not formally cleared | High | Search relevant Nice classes with a qualified professional |
| Domains and social handles | Not verified | Medium | Check target domains, app stores, and priority networks |
| Pronunciation and meaning | Readable but somewhat long | Low | Test recall and spelling with target users |

The working name may be used for development. It must not be represented as trademark-cleared or legally exclusive.

## Product audit

| Area | Status | Finding |
|---|---|---|
| User problem | Good | Fit uncertainty, color confusion, and climate mismatch are understandable problems |
| First-use value | Good | A user can receive three outputs without creating an account |
| Geographic relevance | Good | Tropical wet/dry logic avoids assuming that every user has four seasons |
| Body measurement | Guarded | Guided tape input remains primary; the photo scan is consent-gated, height-calibrated, non-retained, and labeled experimental |
| Universal sizing | Weak by nature | Alpha sizes are not standardized across brands or garments |
| Personal color | Exploratory | Broad palettes can inspire, but lighting and subjective interpretation limit accuracy |
| Explainability | Good | Results include fit notes, palette guidance, fabrics, and model versions |
| Commerce readiness | Not ready | No garment measurements, inventory, price, returns feedback, or retailer integration |

## AI and data audit

### High-priority limitations

1. The training data is synthetic. Reported model confidence is class probability within the demonstration model, not real-world accuracy.
2. There is no calibrated validation set or subgroup evaluation.
3. The size model predicts a generic label rather than garment-specific fit.
4. The color model uses selected RGB values, not calibrated spectrophotometry or controlled photography.
5. The outfit catalog is small; nearest-neighbor retrieval can return a partially matching outfit when an exact combination is absent.

### Controls already present

- numeric ranges are validated by Pydantic and Flutter forms;
- a scan photo is transmitted only after explicit consent, processed in memory, and not retained or reused for training;
- every size and color response includes a limitation statement;
- deterministic random seeds make the demo reproducible;
- model versions are returned by the API;
- tropical, temperate, arid, and cold climate logic is explicit and testable.

### Controls required before production

- datasheets and consent records for every training source;
- separate development, calibration, and locked evaluation sets;
- subgroup sample-size requirements and error reporting;
- calibrated confidence and an abstain/ask-for-more-information outcome;
- model registry, signed artifacts, rollback, and monitoring;
- human review of catalog rules and high-impact changes;
- user feedback labels that do not silently retrain production models.

## Privacy and security audit

Body measurements are sensitive personal data even when they are not legally classified as biometric identifiers. A future face/body-photo workflow increases the risk substantially.

### Current MVP

- Data is transmitted to the configured API but not persisted by the included code.
- CORS is configured for local development only.
- The app has a local demonstration authentication gate, but no identity provider, credential storage, or secure server session.
- There are no analytics or advertising trackers.

### Production blockers

- TLS and strict production origins;
- authentication and authorization;
- encryption at rest with separated keys;
- data minimization and field-level retention schedules;
- user consent, access, export, correction, and deletion;
- rate limits, abuse detection, audit logs, and incident response;
- secrets management and dependency scanning;
- a documented legal basis in every launch market;
- a data-protection impact assessment for camera-based measurement.

Raw body or face photos should be processed on-device where practical and deleted immediately by default. They should never be reused for model training without separate, specific, revocable consent.

## Inclusive-design audit

### Positive choices

- avoids gender as a required sizing input;
- includes sizes 2XS through 4XL in the demonstration reference set;
- calls measurements “chest / bust” and uses neutral language;
- does not infer ethnicity, gender, health, or attractiveness;
- uses local climate instead of fashion calendars alone.

### Gaps to test

- screen-reader labels and focus order;
- color contrast and non-color result cues;
- users who cannot stand or use a measuring tape;
- seated measurements and adaptive clothing needs;
- headwear, modest-fashion, maternity, prosthetic, and sensory preferences;
- size coverage beyond the current demonstration range;
- nonbinary and culturally diverse style taxonomies.

## Technical audit

### Strengths

- Flutter UI and ML service are cleanly separated;
- API contracts have typed validation;
- API endpoint tests cover health, invalid measurements, size, color, and tropical season behavior;
- API location is injected at build time;
- no database or cloud dependency is required for the MVP.

### Known technical debt

- app state is in-memory and resets on restart;
- no offline cache or retry policy;
- no generated typed API client;
- no localization or unit conversion;
- no production authentication, persistence, telemetry, or deployment configuration;
- development CORS origins must be made explicit for each served port;
- model training currently occurs at process start instead of loading signed artifacts;
- catalog breadth and test coverage must expand before user trials.

## Release decision

**Approved for local prototype/demo use.**  
**Not approved for production sizing claims, public camera scanning, medical/body assessment, automated purchasing, or storage of personal profiles.**

The next safe milestone is a small, consented usability study using guided measurements and clearly labeled recommendations. Brand clearance and privacy engineering should run in parallel.
