# Stylorista-AI product plan

## Product thesis

People do not need more random outfit images. They need fashion recommendations grounded in their measurements, coloring, climate, occasion, comfort, and the actual construction of garments.

Stylorista-AI should act as a transparent styling assistant: collect the minimum necessary information, explain its recommendations, let users correct the profile, and never present an estimate as a guaranteed fit.

## Brand working definition

- **Working name:** Stylorista-AI
- **Descriptor:** Personal fashion intelligence
- **Tagline:** Fit. Tone. Season. You.
- **Promise:** Fashion guidance built from the user's real context
- **Voice:** Warm, precise, inclusive, never judgmental
- **Visual direction:** Editorial cream and ink, berry accent, moss for utility, restrained gold for color analysis

The name is memorable and communicates “style + fashionista,” but it is not proven legally unique. See `AUDIT.md`.

## MVP user journey

1. The user records guided body measurements in centimetres.
2. The API recommends a general starting-size label and explains where measurements may cross sizes.
3. The user selects representative skin, natural hair-root, and iris colors under daylight.
4. The API returns a four-season color direction with palette, neutrals, metals, and usage guidance.
5. The user selects climate, hemisphere, occasion, and style direction.
6. The recommender combines the current month, climate cycle, color profile, and starting size into an outfit system.

## MVP scope

### Fit profile

Captured measurements:

- height;
- neck;
- shoulder width;
- chest or bust;
- underbust;
- natural waist;
- high hip;
- full hip;
- sleeve length;
- wrist;
- inseam.

The minimum usable set is height, chest/bust, waist, and full hip. The output is a starting point, not a universal size. Each retailer ultimately requires garment measurements, ease, fabrication, and pattern-block information.

### Personal color

The MVP accepts deliberate color selections instead of a face photograph. It provides one of four broad styling directions: Spring, Summer, Autumn, or Winter. The result is aesthetic advice, not a biological, racial, or health classification.

### Current-season styling

The MVP handles:

- tropical wet and dry seasons;
- northern and southern temperate seasons;
- arid hot and mild periods;
- cold-climate cold and mild periods;
- everyday, work, event, and travel occasions;
- minimal, classic, street, and romantic style directions.

The initial wardrobe catalog is deliberately small and curated so every recommendation can be inspected.

## Technical architecture

```text
Flutter client
    ├── Guided measurement form
    ├── Color selectors
    ├── Seasonal context
    └── Result explanations
             │ JSON/HTTPS
             ▼
FastAPI service
    ├── Pydantic validation
    ├── scikit-learn size classifier
    ├── scikit-learn color classifier
    └── nearest-neighbor outfit recommender
```

The API base URL is a Dart compile-time setting (`API_BASE_URL`). Production should add authentication, encrypted storage, strict CORS origins, rate limiting, observability, model registry, and user-controlled deletion.

## Model strategy

### Current demonstration models

- **Size:** imputation, scaling, and random-forest classification over a deterministic synthetic reference set.
- **Color:** engineered color/contrast features and random-forest classification over synthetic seasonal profiles.
- **Style:** one-hot categorical encoding and nearest-neighbor retrieval from a curated outfit catalog.

### Production data requirements

- consented, de-identified professional body measurements;
- garment-level measurement charts and pattern-block metadata;
- outcomes such as kept/returned, too tight/loose, and alteration locations;
- controlled-light color samples evaluated by trained color analysts;
- climate, fabric, occasion, mobility, modesty, and comfort labels;
- representation across body shapes, ages, disabilities, gender expressions, and skin tones.

No production model should be trained on scraped private images or infer protected traits.

## Delivery roadmap

### Phase 0 — Foundation (implemented)

- responsive Flutter shell;
- guided measurements;
- personal-color selections;
- climate-aware current-season logic;
- three scikit-learn workflows;
- API validation, tests, and disclaimers;
- product and risk audit.

### Phase 1 — Validated profile beta

- user authentication and encrypted profile storage;
- measurement tutorial illustrations;
- centimetre/inch conversion;
- brand-specific garment charts;
- corrections and feedback after each recommendation;
- accessibility and screen-reader testing;
- consent, export, and delete-account flows.

**Exit metric:** at least 80% of beta users can complete a profile without assistance; zero sensitive-data retention outside the documented policy.

### Phase 2 — Commerce-quality fit

- partner garment measurements, fabric stretch, ease, and silhouette data;
- separate top, bottom, dress, footwear, and accessory sizing;
- calibrated evaluation set measured by trained professionals;
- subgroup performance and confidence calibration;
- recommendation abstention when confidence or coverage is inadequate.

**Exit metric:** materially lower size-related return rate than a standard chart for pilot products, with no unacceptable subgroup gap.

### Phase 3 — Camera-assisted measurement research

- explicit opt-in capture;
- front and side capture with a calibration reference;
- pose and garment-quality checks;
- on-device landmark extraction where practical;
- immediate deletion of raw images by default;
- professional-measurement validation and adversarial privacy review.

Camera assistance must remain an estimate and should fall back to guided tape measurements when capture quality is inadequate.

### Phase 4 — Live wardrobe and weather

- live local weather and severe-weather context;
- digital wardrobe ingestion with explicit rights and deletion controls;
- cost-per-wear and outfit repetition tools;
- shopping only when an existing wardrobe cannot satisfy the brief;
- regional retailers, currencies, and availability.

## Business model options

- **Consumer freemium:** free profile and limited outfits; paid wardrobe planning and packing lists.
- **Retailer SDK/API:** garment-aware fit and styling embedded on product pages.
- **Brand analytics:** aggregate, privacy-preserving fit gaps and unmet size demand.

Do not sell raw body measurements, face imagery, or inferred sensitive traits. Monetization should come from software value, subscriptions, or clearly disclosed commerce—not surveillance.

## Core metrics

- profile completion rate;
- recommendation save rate;
- correction rate and reason;
- size-related return rate;
- recommendation coverage and abstention rate;
- confidence calibration;
- subgroup error gaps;
- deletion-request completion time;
- repeat outfits before new-purchase recommendations;
- customer trust and explanation usefulness.

