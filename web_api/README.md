# 🌐 Fake API — Simulated Network Calls

**Fake API** is a generic API built with **FastAPI**.  
It simulates different types of HTTP requests (GET, POST, with or without latency, light or heavy payloads) to help measure energy impact across various virtualization platforms (Docker, VM, microVM…).

## Project Goals

- Simulate network requests with variable load.
- Provide a stable and configurable API for testing energy consumption.
- Study the impact of virtualized environments on network performance.
- Generate reproducible and exploitable log data.

## Step-by-step Installation

### 1. Clone the repository

```bash
git clone <your-repository-url>
cd fakeApi
```

### 2. Create a virtual environment

```bash
uv venv
source .venv/bin/activate
```

### 3. Install dependencies

```bash
make install
```
> Ou manuellement :

> uv pip install .

## Install the project locally

uv pip install .

## Run the API locally

```bash
make run
```

This command calls `uvicorn app.app:app --reload` which starts the server at [http://localhost:8000](http://localhost:8000).

## Interactive API Documentation 

FastAPI automatically provides interactive documentation for the API:
Swagger UI: http://localhost:8000/docs
ReDoc: http://localhost:8000/redoc

These interfaces allow you to:
- Explore and test all available endpoints directly from your browser
- View required parameters and expected response formats
- Understand the request/response models based on the defined schemas

## API Features

| Method  | Endpoint             | Description                                                              |
|---------|----------------------|--------------------------------------------------------------------------|
| `GET`   | `/simulate/normal`   | Simple response with a short message                                     |
| `GET`   | `/simulate/heavy`    | Heavy response with repeated text (customizable via `size_kb` parameter)|
| `POST`  | `/simulate/normal`   | Sends a text payload (`content` field)                                   |
| `POST`  | `/simulate/heavy`    | Simulates a heavy payload or sends text                                  |
| `GET`   | `/simulate/delay`    | Responds with simulated delay (`ms` in milliseconds)                     |
| `POST`  | `/simulate/delay`    | Sends payload with simulated delay                                       |

🔎 All responses include a **detailed log**: `call_id`, `timestamp`, `type`, size info, etc.

## Manual API Testing

```bash
curl "http://localhost:8000/simulate/heavy?size_kb=300"

curl -X POST http://localhost:8000/simulate/normal \
     -H "Content-Type: application/json" \
     -d '{"content": "This is a test"}'

curl -X GET "http://localhost:8000/simulate/delay?ms=1000"
```

## Automated Tests

### Run the tests

```bash
make test
```

### Covered cases

- Standard and heavy GET/POST requests
- Simulated latency
- Empty or defined payloads
- Error handling (invalid types, negative sizes…)

## Available Makefile Commands

```makefile
make install  # Install all Python dependencies from requirements.txt
make run      # Run the API locally with uvicorn (hot reload enabled)
make test     # Run all unit tests with pytest
```

## Project Structure

web_api/
├── app/
│   ├── app.py             # FastAPI application instance
│   ├── main.py            # Entry point (used by uvicorn)
│   ├── helpers.py         # Utility functions (logging, payload generation)
│   └── routes/
│       └── simulation_routes.py  # All /simulate/... endpoints
├── tests/
│   ├── test_simulation.py # Functional tests
│   └── test_errors.py     # Error and edge case tests
├── Makefile               # Developer commands
├── pyproject.toml         # Project dependencies and metadata
├── uv.lock                # Locked versions of all dependencies
└── README.md              # This file

This project uses pydantic schemas defined in a shared module: 
shared_module/greenux_shared_module/models/payload

## File-by-file Description

| File / Folder              | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| `app/app.py`              | Initializes the FastAPI application                                         |
| `app/routes/simulate.py`  | Declares all `/simulate/...` endpoints                                      |
| `app/helpers.py`          | Generates logs and payloads                                                 |
| `app/schemas.py`          | Pydantic model for POST payloads                                            |
| `tests/test_simulation.py`| Tests expected behavior of endpoints                                        |
| `tests/test_errors.py`    | Tests for invalid types, negative sizes, empty payloads, etc.               |
| `pyproject.toml`          | Project configuration and dependencies  
| `uv.lock`                 | Lock file for deterministic builds using uv             |
| `Makefile`                | Useful developer commands (`install`, `test`, `run`)                        |
| `README.md`               | This file, project documentation                                            |

## About

This project was developed as part of a study on the **energy efficiency** of virtualized systems.  
Its goal is to offer a reproducible, configurable test base to analyze the runtime impact of different execution environments on performance and energy consumption.

> Made with ❤️ and with FastAPI