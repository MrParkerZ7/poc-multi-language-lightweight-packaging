"""Trivial CLI — packaged as a PEX (Python EXecutable) zipapp+."""

import json
import uuid
from datetime import datetime, timezone


def main() -> None:
    payload = {
        "hello": "world",
        "language": "python",
        "uuid": str(uuid.uuid4()),
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    print(json.dumps(payload))


if __name__ == "__main__":
    main()
