"""Minimal HTTP server exposing GET /health on PORT (default 6713)."""

from __future__ import annotations

import os

from fastapi import FastAPI

app = FastAPI()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("PORT", 6713))
    uvicorn.run("server:app", host="0.0.0.0", port=port)
