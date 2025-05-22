/ an automatic UX block that has a precondition that must be met before it is executed
```ux :test
exec: printf "$MISSING_VARIABLE"
name: SPECIES
required:
- MISSING_VARIABLE
```
@import bats-document-configuration.md