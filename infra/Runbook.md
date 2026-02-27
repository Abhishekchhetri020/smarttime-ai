# Runbook (Phase 1)

## Backend (Functions)
cd backend/functions
npm install
npm run build
npm run serve

## Solver
cd solver
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8080

## Admin Web
cd admin-web
npm install
npm run dev
