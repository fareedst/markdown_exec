# Demo variable porting

::: Set the VAULT value in memory.
::: Call this block prior to `show` to demonstrate in-memory value being written to script.

```vars :set
VAULT: This variable was set by the "set" block.
```

::: This is a Port block that saves current/live environment variable values into the generated script.

```port :[vault]
VAULT
VAULT2
```

::: This block requires the Port block and displays the value.
::: The Port block contributes the variable VAULT to the generated script.

```bash :show +[vault]
: ${VAULT:=This variable has not been set.}
source bin/colorize_env_vars.sh
colorize_env_vars '' VAULT
```
@import example-document-opts.md
```opts :(document_opts)
dump_inherited_lines: true
execute_in_own_window: false
output_execution_report: false
output_execution_summary: false
pause_after_script_execution: true
```