"""Promptfoo provider — generated for agent root invoke."""

from __future__ import annotations

import importlib
import os
import sys
from pathlib import Path
from typing import Any

_STATE: dict[str, Any] = {}


def setup_dependencies(precondition: dict | None, config: dict | None) -> None:
    """Seed mock/tool state before invoking the agent."""
    global _STATE
    _STATE = dict(precondition or {})
    if config:
        _STATE.setdefault("config", config)


def _resolve_llm(config: dict):
    base_url = os.environ["LITELLM_BASE_URL"]
    api_key = os.environ["LITELLM_API_KEY"]
    try:
        from langchain_openai import ChatOpenAI
    except ImportError as exc:
        raise RuntimeError("langchain_openai is required for agent eval") from exc
    return ChatOpenAI(
        model=config.get("model", "gpt-5.1"),
        base_url=base_url,
        api_key=api_key,
        temperature=config.get("temperature", 0),
    )


def _invoke_agent(llm, user_input: str) -> str:
    workspace = Path(__file__).resolve()
    for _ in range(8):
        workspace = workspace.parent
        if (workspace / ".codevalid").is_dir():
            break
    if str(workspace) not in sys.path:
        sys.path.insert(0, str(workspace))
    module = importlib.import_module("agent")
    target = getattr(module, "invoke", None)
    if target is None:
        raise RuntimeError("Agent entry invoke not found in agent")
    if hasattr(target, "invoke"):
        result = target.invoke({"input": user_input}, config={"configurable": {"llm": llm}})
        if isinstance(result, dict):
            return str(result.get("output", result))
        return str(result)
    return str(target(user_input))


def call_api(prompt: str, options: dict, context: dict) -> dict:
  config = options.get("config", {})
  vars_ = context.get("vars", {})
  setup_dependencies(vars_.get("precondition"), config)
  llm = _resolve_llm(config)
  output = _invoke_agent(llm, prompt)
  return {"output": output}
