"""Trivial CLI — prints {hello, language, uuid, timestamp} as one line of JSON."""

import json
import uuid
from datetime import datetime, timezone

# Realistic "enterprise" imports — pulled in but not heavily used here.
# These are what a typical Python project ships even for trivial CLIs.
import requests  # noqa: F401  (transitive: urllib3, certifi, charset-normalizer, idna)
import rich      # noqa: F401  (transitive: markdown-it-py, pygments)


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
