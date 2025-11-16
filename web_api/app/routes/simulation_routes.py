from fastapi import APIRouter
from pydantic import BaseModel
from app.helpers import generate_log, generate_big_string
import time

router = APIRouter()

# Simple payload models
class Payload(BaseModel):
    content: str = ""

class DelayPayload(BaseModel):
    delay_ms: int = 100

class HeavyPayload(BaseModel):
    size_kb: int = 500


# 🔷 GET endpoints

@router.get("/simulate/normal")
def get_normal():
    data = {"message": "This is a normal GET response."}
    log = generate_log({
        "type": "GET",
        "response_size_kb": len(str(data)) // 1024
    })
    return {**log, "response": data}


@router.get("/simulate/heavy")
def get_heavy(size_kb: int = 500):
    data = {"payload": generate_big_string(size_kb)}
    log = generate_log({
        "type": "GET",
        "response_size_kb": size_kb
    })
    return {**log, "response": data}


@router.get("/simulate/delay")
def get_delay(ms: int = 500):
    time.sleep(ms / 1000)
    log = generate_log({"type": "GET", "delay_ms": ms})
    return {**log, "response": f"Simulated delay of {ms} ms"}


# 🔷 POST endpoints

@router.post("/simulate/normal")
def post_normal(payload: Payload):
    size = len(payload.content.encode()) if payload.content else 0
    log = generate_log({
        "type": "POST",
        "received_size_kb": size // 1024
    })
    msg = (payload.content or "")[:100] or "Aucun contenu"
    return {
        **log,
        "response": {"message": msg}
    }


@router.post("/simulate/heavy")
def post_heavy(payload: HeavyPayload):
    content = generate_big_string(payload.size_kb)
    size = len(content.encode())
    log = generate_log({
        "type": "POST",
        "received_size_kb": size // 1024,
        "generated": True
    })
    return {
        **log,
        "response": {
            "message": f"Heavy payload processed, size: {size} bytes"
        }
    }


@router.post("/simulate/delay")
def post_delay(payload: DelayPayload):
    time.sleep(payload.delay_ms / 1000)
    
    log = generate_log({
        "type": "POST",
        "delay_ms": payload.delay_ms
    })
    return {
        **log,
        "response": {"message": f"Simulated delay of {payload.delay_ms} ms"}
    }


# 🔷 Simple test endpoints for benchmarking

@router.get("/api/light")
def api_light():
    """Lightweight endpoint for performance testing"""
    return {"status": "ok", "message": "Light response", "data": {"value": 42}}


@router.get("/api/heavy")
def api_heavy():
    """Heavy payload endpoint for performance testing"""
    data = generate_big_string(500)  # 500 KB
    return {"status": "ok", "message": "Heavy response", "size_kb": 500, "data": data[:100]}


@router.get("/api/slow")
def api_slow():
    """Endpoint with artificial delay for latency testing"""
    time.sleep(1)  # 1 second delay
    return {"status": "ok", "message": "Slow response", "delay_ms": 1000}
