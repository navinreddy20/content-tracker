---
description: Launch the Telusko Workflow Engine — FastAPI backend on port 8000 and static frontend on port 8080. No smoke tests.
---

## How to run this app

### 1. Start the backend

From the `backend/` directory:

```
uv run python start.py
```

This starts FastAPI on http://127.0.0.1:8000 with hot-reload.

### 2. Start the frontend

From the repo root:

```
python -m http.server 8080 --directory frontend
```

This serves the static frontend on http://127.0.0.1:8080.

### 3. Report

Tell the user both URLs and stop. Do NOT run curl smoke tests. Do NOT hit any endpoints. Do NOT verify responses. Just launch and report.
