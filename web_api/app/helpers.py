from uuid import uuid4
from datetime import datetime, UTC


# Utility to generate a big payload string
def generate_big_string(size_kb: int):
    base = "You may say I'm a dreamer, " \
        "But I'm not the only one, " \
        "I hope someday you'll join us, " \
        "And the world will be as one"
    repetitions = (size_kb * 1024) // len(base)
    return base * repetitions


# Utility to generate a basic log to include in responses
def generate_log(metadata: dict[str, str]) -> dict[str, str]:
    return {
        "call_id": str(uuid4()),
        "timestamp": datetime.now(UTC).isoformat(),
        **metadata
    }
