from fastapi import APIRouter
from greenux_shared_module.models.payload import Payload, DelayPayload, HeavyPayload
from app.helpers import generate_log, generate_big_string
import time

router = APIRouter()


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
    if payload.content:
        content = payload.content
        generated = False
    else:
        content = generate_big_string(payload.size_kb)
        generated = True

    size = len(content.encode())
    log = generate_log({
        "type": "POST",
        "received_size_kb": size // 1024,
        "generated": generated
    })
    msg = (payload.content or "")[:100] or "Aucun contenu"
    return {
        **log,
        "response": {
            "message": msg + f", Taille finale : {size} octets,  "
        }
    }


@router.post("/simulate/delay")
def post_delay(payload: DelayPayload):
    time.sleep(payload.ms / 1000)

    content_preview = (payload.content or "")[:100] or "Aucun contenu"
    size = len(payload.content.encode()) if payload.content else 0

    log = generate_log({
        "type": "POST",
        "delay_ms": payload.ms,
        "received_size_kb": size // 1024
    })
    msg = f"Délai simulé de {payload.ms}ms - contenu : {content_preview}"
    return {
        **log,
        "response": {"message": msg}
    }
