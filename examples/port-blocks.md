# Demo variable porting

::: This block requires the Port block and displays the value.
::: The Port block contributes the variable VAULT to the generated script.

```bash :show +(vault)
: ${VAULT:=This variable has not been set.}
source bin/colorize_env_vars.sh
colorize_env_vars '' VAULT
```

::: Set the VAULT value in memory.
::: Call this block prior to `show` to demonstrate in-memory value being written to script.

```vars :set
VAULT: This variable was set by the "set" block.
```

::: There is an invisible Port block that saves current/live environment variable values into the generated script.

```port :(vault)
VAULT
```
