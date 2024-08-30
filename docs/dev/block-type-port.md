```vars :[set_vault_1]
VAULT: 1
```

::: This is a Port block that saves current/live environment variable values into the generated script.

```port :[vault]
VAULT
```

```bash :VAULT-is-export
exported_vault=$(export -p | grep '^declare -x VAULT')
# (No output, var is not exported)
```

::: This block requires the Port block and displays the value.
::: The Port block contributes the variable VAULT to the generated script.

```bash :show +[set_vault_1] +[vault]
: ${VAULT:=This variable has not been set.}
echo "VAULT: $VAULT"
```

@import bats-document-configuration.md
