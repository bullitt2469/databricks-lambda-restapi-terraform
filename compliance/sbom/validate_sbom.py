#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def fail(msg: str) -> None:
    print(f"FAIL: {msg}")
    sys.exit(1)


def main() -> int:
    sbom_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("compliance/sbom/sbom.cyclonedx.json")
    if not sbom_path.exists():
        fail(f"SBOM file not found: {sbom_path}")

    with sbom_path.open("r", encoding="utf-8") as f:
        data = json.load(f)

    if data.get("bomFormat") != "CycloneDX":
        fail("bomFormat must be CycloneDX")
    if not data.get("specVersion"):
        fail("specVersion is required")
    if not data.get("serialNumber"):
        fail("serialNumber is required")

    metadata = data.get("metadata", {})
    if not metadata.get("timestamp"):
        fail("metadata.timestamp is required")
    component = metadata.get("component", {})
    if not component.get("name"):
        fail("metadata.component.name is required")
    if not component.get("version"):
        fail("metadata.component.version is required")

    components = data.get("components", [])
    if not components:
        fail("components must include at least one entry")

    for idx, comp in enumerate(components):
        name = comp.get("name")
        version = comp.get("version")
        purl = comp.get("purl")
        if not name:
            fail(f"components[{idx}].name is required")
        if not version:
            fail(f"components[{idx}].version is required")
        if not purl:
            fail(f"components[{idx}].purl is required")

    dependencies = data.get("dependencies", [])
    if not dependencies:
        fail("dependencies section is required")

    print(f"PASS: SBOM minimum element checks succeeded for {sbom_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
