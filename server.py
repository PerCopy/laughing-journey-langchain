"""Minimal HTTP server wrapping the LangChain refund agent.

Exposes:
  GET  /health          — liveness probe (returns 200 {\"status\": \"ok\"})
  POST /invoke          — run the agent (body: {\"input\": \"<customer request>\"})
"""

from __future__ import annotations

import os

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from pydantic import BaseModel

app = FastAPI(title="refund-agent")


@app.get("/health")
async def health() -> JSONResponse:
    return JSONResponse({"status": "ok"})


class InvokeRequest(BaseModel):
    input: str


@app.post("/invoke")
async def invoke_agent(req: InvokeRequest) -> JSONResponse:
    from agent import invoke  # lazy import keeps startup fast

    result = invoke(req.input)
    return JSONResponse({"output": result})


if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", "6713"))
    uvicorn.run("server:app", host="0.0.0.0", port=port)
