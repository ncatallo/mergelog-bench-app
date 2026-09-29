# mergelog-bench-app

The reference app for The Merge Log video *Coolify vs Dokploy vs Docker Compose*:
a static frontend (nginx), a small API (FastAPI) and PostgreSQL, deployed the same way with
each tool so their behaviour can be compared.

- `api/release.py` is the only file a release changes (`VERSION`; `BROKEN` simulates a bad release).
- `deploy/compose/` is the hand-written reference deploy (Compose + Caddy).
- All secrets come from environment variables; nothing sensitive is committed.
