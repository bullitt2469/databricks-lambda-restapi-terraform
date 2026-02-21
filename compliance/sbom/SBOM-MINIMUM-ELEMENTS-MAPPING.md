# SBOM Minimum Elements Mapping (CISA 2025-Aligned)

This repository includes a CycloneDX SBOM at:

- `/Users/caseycook/Desktop/Work Source Code/databricks-lambda-restapi-terraform/compliance/sbom/sbom.cyclonedx.json`

## Source Baseline and Constraints

- Primary reference requested: [CISA 2025 Minimum Elements for SBOM](https://www.cisa.gov/resources-tools/resources/2025-minimum-elements-software-bill-materials-sbom)
- Environment note: direct retrieval of the CISA page returned HTTP 403 in this execution environment on February 21, 2026.
- Alignment approach: this mapping uses available CISA-published summary language and federal SBOM best practices, implemented via CycloneDX required metadata and process controls.

## Implemented Minimum Elements

| Element Category | Implemented in This Repo | Location |
|---|---|---|
| SBOM data format | CycloneDX JSON (`specVersion: 1.6`) | `compliance/sbom/sbom.cyclonedx.json` |
| Component name | Each dependency includes `name` | `compliance/sbom/sbom.cyclonedx.json` |
| Component version | Each dependency includes `version` | `compliance/sbom/sbom.cyclonedx.json` |
| Supplier/author | `metadata.component.supplier` and `metadata.authors` | `compliance/sbom/sbom.cyclonedx.json` |
| Unique identifier | `serialNumber` and component `purl` values | `compliance/sbom/sbom.cyclonedx.json` |
| Dependency relationships | `dependencies` section | `compliance/sbom/sbom.cyclonedx.json` |
| Timestamp | `metadata.timestamp` | `compliance/sbom/sbom.cyclonedx.json` |
| Scope / lifecycle clarity | `scope` per component and SBOM lifecycle property | `compliance/sbom/sbom.cyclonedx.json` |
| Evidence and traceability | `evidence.occurrences` references source files | `compliance/sbom/sbom.cyclonedx.json` |
| Automation support | CI validation gate for required fields | `.github/workflows/ci.yml`, `compliance/sbom/validate_sbom.py` |
| Governance / operations | This policy mapping + NIST control mapping updates | `compliance/sbom/SBOM-MINIMUM-ELEMENTS-MAPPING.md`, `compliance/NIST-800-53r5-control-matrix.md` |

## Best-Practice Controls Applied

- Machine-readable SBOM stored with compliance artifacts.
- Dependency provenance references source files.
- CI gate fails when minimum SBOM fields are missing.
- SBOM is tied to federal compliance documentation and control evidence.
- SBOM includes both application and IaC/provider dependencies.

## Operational Guidance

1. Update the SBOM when dependencies, providers, or workflow components change.
2. Keep version pinning strategy explicit (currently lower-bounded constraints).
3. Generate signed SBOM attestations in release pipelines where agency policy requires provenance attestation.
4. Feed SBOM into enterprise vulnerability management and asset inventory tools.
