# Kilimo — Resilient Crop Rotation Decision Support

Kilimo is a decision-support prototype for exploring climate-resilient crop choices and rotations in Kenya. It combines NASA POWER climate climatology with regional soil profiles and an agronomic crop catalog to surface water stress, soil risks, crop suitability, and alternative rotation strategies. It is designed to help farmers, agronomists, and agricultural programs compare options—not to replace local agronomic advice or field measurements.

> **NASA Space Apps Challenge context:** The backend identifies the project as a decision-support system for the **Resilient Crop Rotations** challenge. The goal is to make satellite-informed climate context understandable and actionable through crop and rotation comparisons.

## What Kilimo does

- Retrieves temperature, precipitation, humidity, and solar-radiation climatology from the [NASA POWER API](https://power.larc.nasa.gov/docs/services/api/temporal/climatology/), using a location's latitude and longitude.
- Builds monthly climate summaries, including estimated evapotranspiration, water deficit, soil moisture, bare-soil periods, and vulnerability windows.
- Looks up regional soil properties and enriches them with derived indicators such as pH/organic-matter concerns, erosion risk, and possible amendments.
- Maintains a crop catalog with crop water demand, temperature and pH ranges, rooting depth, nitrogen-fixation potential, drought/heat tolerance, and other agronomic attributes.
- Exposes API endpoints for crop and region data, field vulnerability analysis, individual or batch crop-suitability predictions, and rotation recommendations and scenario simulation.

## How the data and model fit together

For a suitability request, the Go API fetches NASA POWER climatology, obtains a regional soil profile and a crop profile, then assembles a 16-feature `ModelInputVector`. Features include rainfall, temperature, soil moisture, evaporative-stress index, slope, soil pH and organic matter, crop water demand and root depth, and farmer priorities. `internal/ml/engine.go` normalizes these inputs and evaluates them with a Gorgonia computation graph (16 → 32 → 16 → 4). Its four outputs are post-processed into suitability, resilience, soil-health, and economic scores, with additional agronomic rules such as water-deficit penalties and nitrogen-fixation or deep-root bonuses.

**Important model transparency:** the current Gorgonia weights are initialized from hand-coded, agronomically motivated values in `initCalibratedWeights`; this repository does not include a model-training pipeline or evidence that these weights were fitted against measured farm outcomes. Treat the results as an exploratory prototype, not a validated predictive model. Before field use, calibrate and evaluate against local agronomic expertise and observed yield/soil data, and publish the evaluation methodology.

## Data sources and limitations

- **Live external data:** `internal/nasa/nasa.go` requests NASA POWER point climatology. If the request fails or required values are missing, the service uses a Kenya climatology fallback. Observation responses include a `source` field: `NASA_POWER_LIVE` or `NASA_SATELLITE_CLIMATOLOGY_FALLBACK`.
- **Local reference data:** the backend loads Kenya climate history and regional soil CSVs from `training_data/` (see `internal/server/server.go` for the expected paths).
- **Derived estimates:** response fields are named for datasets/missions including SMAP, ECOSTRESS, GPM, MODIS, SRTM, and GRACE. In the current implementation, most of these are estimated or derived from POWER climatology and fixed assumptions; the code does not independently fetch all of those satellite products. In particular, elevation/slope and some ET/vegetation/water-storage values use defaults or simplified formulas. These should not be presented as direct observations from those missions without implementing and validating the corresponding data integrations.
- **Rotation scoring:** rotation strategy templates and some score/benefit values are currently hand-authored in `internal/rotation/rotation.go`. Simulation adjusts scores using simple scenario rules. Validate and replace illustrative projections with transparent, locally reviewed calculations before making quantitative impact claims.
- NASA POWER climatology represents long-term climate normals, not necessarily current or near-real-time field conditions. Satellite and soil data are spatial averages and should be combined with ground measurements where available.

## API

The Go service defaults to port `8080` (override with `PORT`). The API is rooted at `/api/v1`:

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/` | Project/service information |
| GET | `/health` | Server, database, and model status |
| GET | `/api/v1/regions` | Available regional soil profiles |
| GET | `/api/v1/crops` | Crop catalog |
| GET | `/api/v1/crops/:id` | Crop profile by ID (for example, `maize`) |
| POST | `/api/v1/nasa/observations` | NASA POWER request and derived environmental summary |
| GET | `/api/v1/nasa/metrics-info` | Explanations of agronomic metrics |
| POST | `/api/v1/analyze/vulnerabilities` | Bare-soil, climate-stress, and crop-cycle diagnosis |
| POST | `/api/v1/ml/predict-crop-suitability` | Predict scores for one crop |
| POST | `/api/v1/ml/batch-predict` | Compare crop predictions in a batch |
| POST | `/api/v1/rotations/recommend` | Compare crop-rotation strategies |
| POST | `/api/v1/rotations/simulate` | Explore rainfall/temperature scenario changes |

Example observation request:

```bash
curl -X POST http://localhost:8080/api/v1/nasa/observations \
  -H 'Content-Type: application/json' \
  -d '{"latitude":-0.3031,"longitude":36.08}'
```

Inspect the returned `source` field to see whether the request used NASA POWER or the fallback. Coordinates above are an example location, not a claim that the returned data is a live field measurement.

## Run locally

### Backend

Requirements: Go (the module declares Go 1.22.2) and network access for NASA POWER requests. From the repository root:

```bash
go test ./...
go run ./cmd/api
```

The API listens on `http://localhost:8080` by default. The server loads the climate and soil CSVs using paths under `training_data/`.

### Flutter frontend

The `frontend/` directory is a Flutter project. Install Flutter, then run:

```bash
cd frontend
flutter pub get
flutter run
```

The current `frontend/lib/main.dart` is still Flutter's counter starter screen; it is not yet a Kilimo client wired to the API.

### Docker Compose

`docker-compose.yml` defines the Go app, PostgreSQL, and a frontend image. Configure the database and app variables before starting it:

```dotenv
APP_ENV=development
PORT=8080
BLUEPRINT_DB_HOST=psql_bp
BLUEPRINT_DB_PORT=5432
BLUEPRINT_DB_DATABASE=kilimo
BLUEPRINT_DB_USERNAME=kilimo
BLUEPRINT_DB_PASSWORD=change-me
BLUEPRINT_DB_SCHEMA=public
```

Then run:

```bash
docker compose up --build
```

**Deployment note:** inspect and validate the Docker build before relying on it. The current Dockerfile's frontend stage expects `frontend/package*.json` and an npm build, while the checked-in frontend is Flutter (`pubspec.yaml`). The repository's `Makefile` also uses npm commands for its `run` target. Those paths may need alignment with the actual Flutter app before the combined container/development workflow works end to end. PostgreSQL is included in Compose for health reporting; the current feature logic primarily uses in-memory/catalog and CSV data.

## Project layout

```text
cmd/api/                 Go API entry point and graceful shutdown
internal/server/         HTTP routes and request handlers
internal/nasa/           NASA POWER client, fallback, and environmental derivations
internal/ml/              Gorgonia inference engine and agronomic post-processing
internal/rotation/        Rotation recommendations and scenario simulation
internal/crops/           Crop catalog and agronomic attributes
internal/soil/            Regional soil profiles and derived soil indicators
internal/database/        PostgreSQL connection and health checks
training_data/            Kenya climate and soil datasets
frontend/                 Flutter application scaffold
```

## Roadmap for a stronger, more credible demo

1. **Make the experience tangible:** replace the Flutter starter screen with a location/region form, crop and farmer-priority inputs, a NASA/fallback source badge, and clear recommendation cards.
2. **Show evidence and uncertainty:** display the specific input factors behind every score, explain which values are measured, climatological, assumed, or user-provided, and show data timestamps and missing-data warnings.
3. **Strengthen the science:** integrate verified source-specific products where claimed, record data provenance, compare derived values with ground observations, and have local agronomists review crop calendars and assumptions.
4. **Validate the model:** create a reproducible training/evaluation workflow, use locally relevant outcomes, compare against simple baselines, report metrics and limitations, and avoid implying learned accuracy until supported by evidence.
5. **Make recommendations actionable:** account for planting calendars, seed availability, labor/equipment, local markets, and farmer constraints; explain trade-offs rather than presenting a single score as certainty.
6. **Test and deploy end to end:** add API/request tests and representative fixtures, connect the Flutter app to a configurable API base URL, resolve the npm-versus-Flutter build mismatch, and publish a working demo URL with sample coordinates and a fallback-safe mode.

## Development commands

The repository `Makefile` includes these Go-oriented targets:

```bash
make build
make test
make itest
make clean
```

`make itest` runs database-package tests. `make run` and the Docker frontend build currently reference npm; see the deployment note above before using those targets.

## Disclaimer

Kilimo is an experimental decision-support prototype. Recommendations and projected benefits are not guarantees or professional agronomic advice. Verify local conditions, data sources, crop suitability, and farm economics with qualified local experts before making planting or investment decisions.
