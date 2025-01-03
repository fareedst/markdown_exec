```vars :[set_vault_1]
VAULT: 1
```
```bash :show
echo "Species: $Species"
echo "VAULT: $VAULT"
```
| Variable| Value
| -| -
| Species| ${Species}
| VAULT| ${VAULT}
@import bats-document-configuration.md
```vars :(document_vars)
Species: Not specified
```