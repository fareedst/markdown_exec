/ an automatic UX block that has a precondition that must be met before it is executed
```ux :[document_ux_SPECIES]
default: :exec
exec: printf "$MISSING_VARIABLE"
name: SPECIES
required:
- MISSING_VARIABLE
```
@import bats-document-configuration.md