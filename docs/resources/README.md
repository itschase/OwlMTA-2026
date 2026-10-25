# Resource dossiers

This directory contains the maintained, source-grounded dossier for each audited MTA resource. GitHub Discussions provide an approachable topic and discussion history; these files remain the versioned reference.

Every dossier distinguishes source evidence from runtime verification. Presence under `mods/deathmatch/resources` means the code is in the active tree. It does not by itself prove that a deployed server starts the resource successfully.

## Published batches

| Domain | Dossiers | Review state |
|---|---|---|
| Vehicle foundation | [`vehicle`](vehicle.md) ([Discussion #107](https://github.com/itschase/OwlMTA-2026/discussions/107)), [`vehicle_fuel`](vehicle_fuel.md) ([#108](https://github.com/itschase/OwlMTA-2026/discussions/108)), [`vehicle-interiors`](vehicle-interiors.md) ([#109](https://github.com/itschase/OwlMTA-2026/discussions/109)), [`vehicle_load`](vehicle_load.md) ([#110](https://github.com/itschase/OwlMTA-2026/discussions/110)), [`vehicle_manager`](vehicle_manager.md) ([#111](https://github.com/itschase/OwlMTA-2026/discussions/111)) | Partial source review; runtime unverified |
| Vehicle commerce and identity | [`carradio`](carradio.md), [`carshop-system`](carshop-system.md), [`vehicleplate`](vehicleplate.md) | Full manifest-script source review; runtime unverified |

The complete manifest census remains in [`RESOURCE_CATALOG.md`](../../RESOURCE_CATALOG.md). The required review fields and completion states are defined in [`RESOURCE_AUDIT_PLAYBOOK.md`](../../RESOURCE_AUDIT_PLAYBOOK.md).

Row-by-row progress across all 179 active-tree and archived manifests is recorded in [`RESOURCE_DOCUMENTATION_STATUS.csv`](../../RESOURCE_DOCUMENTATION_STATUS.csv).
