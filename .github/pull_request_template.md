## Description

Describe the change and affected providers or variants.

## Verification

Record commands, package attributes, and results. Leave checks unchecked when not run; explain any gaps.

- [ ] Evaluation: `nix flake check --no-build --no-write-lock-file --option allow-import-from-derivation false`
- [ ] Package builds: list the explicit attributes built (`proton-cachyos`, `proton-cachyos-v3`, or `dw-proton`).
- [ ] Artifact inspection: ran `bash scripts/check-package.sh <attribute> <realized-output>` for each built package.
- [ ] Steam/game testing: describe the host, CPU support for v3 if applicable, and tested package.
- [ ] Updated user documentation where behavior changed.
