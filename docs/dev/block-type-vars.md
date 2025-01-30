```vars :(document_vars)
Species: Not specified
```
```vars :(document_vars)
Genus: Not specified
```
```vars :[set_vault_1]
VAULT: 1
```
```vars :[invalid_yaml]
this is not yaml
```
```bash :show
echo "Species: $Species"
echo "VAULT: $VAULT"
```
| Variable| Value
| -| -
| Species| ${Species}
| Genus| ${Genus}
| VAULT| ${VAULT}
@import bats-document-configuration.md