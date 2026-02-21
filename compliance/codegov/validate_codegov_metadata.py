#!/usr/bin/env python3
import json
import sys
from pathlib import Path


REQUIRED_TOP_LEVEL = ["version", "agency", "measurementType", "releases"]
REQUIRED_RELEASE_FIELDS = [
    "name",
    "description",
    "repositoryURL",
    "permissions",
    "contact",
    "tags",
]


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def main() -> int:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("compliance/codegov/code.json.template")
    if not path.exists():
        fail(f"Code.gov metadata file not found: {path}")

    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"Invalid JSON: {exc}")

    for field in REQUIRED_TOP_LEVEL:
        if field not in data:
            fail(f"Missing top-level field: {field}")

    if not isinstance(data["releases"], list) or not data["releases"]:
        fail("releases must be a non-empty list")

    release = data["releases"][0]
    for field in REQUIRED_RELEASE_FIELDS:
        if field not in release:
            fail(f"Missing release field: {field}")

    permissions = release.get("permissions", {})
    if "usageType" not in permissions:
        fail("permissions.usageType is required")

    contact = release.get("contact", {})
    if "email" not in contact:
        fail("contact.email is required")

    if not isinstance(release.get("tags"), list) or len(release["tags"]) == 0:
        fail("tags must be a non-empty list")

    print(f"PASS: Code.gov metadata minimum checks succeeded for {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
