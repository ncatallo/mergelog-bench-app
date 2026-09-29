import os
from contextlib import asynccontextmanager

import psycopg
from fastapi import FastAPI, Header, HTTPException, Response
from fastapi.middleware.cors import CORSMiddleware

from release import BROKEN, VERSION

DB = os.environ["DATABASE_URL"]
WRITE_TOKEN = os.environ["WRITE_TOKEN"]  # the secret each platform has to deliver


@asynccontextmanager
async def lifespan(app):
    if BROKEN == "boot":
        raise RuntimeError(f"release {VERSION} is broken: crash at boot")
    with psycopg.connect(DB) as c:
        c.execute("CREATE TABLE IF NOT EXISTS notes ("
                  "id serial PRIMARY KEY, body text NOT NULL, created_at timestamptz DEFAULT now())")
    yield


app = FastAPI(lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


@app.get("/health")
def health(response: Response):
    if BROKEN == "health":
        response.status_code = 500
        return {"ok": False, "version": VERSION}
    with psycopg.connect(DB) as c:
        c.execute("SELECT 1")
    return {"ok": True, "version": VERSION}


@app.get("/api/notes")
def list_notes():
    with psycopg.connect(DB) as c:
        rows = c.execute("SELECT id, body, created_at FROM notes ORDER BY id DESC LIMIT 20").fetchall()
    return {"version": VERSION, "notes": [{"id": i, "body": b, "at": t.isoformat()} for i, b, t in rows]}


@app.post("/api/notes", status_code=201)
def add_note(note: dict, authorization: str = Header("")):
    if authorization != f"Bearer {WRITE_TOKEN}":
        raise HTTPException(401, "bad token")
    with psycopg.connect(DB) as c:
        (i,) = c.execute("INSERT INTO notes (body) VALUES (%s) RETURNING id", (note["body"],)).fetchone()
    return {"id": i, "version": VERSION}
