"""3-best Python: trivial CLI bundled by PyOxidizer with stripped CPython + memory-only modules."""

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
