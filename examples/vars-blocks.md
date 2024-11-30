@import example-document-opts.md
```opts :(document_opts)
execute_in_own_window: false
output_execution_report: false
output_execution_summary: false
pause_after_script_execution: true
```
The hidden block "(defaults)" sets the environment variable VAULT to "default" if it is unset.
```bash :(defaults)
: ${VAULT:=default}
```

::: Select below to trigger. If it prints "VAULT: default", the shell block was processed.
The named block prints the environment variable VAULT. It requires hidden block "(defaults)" before printing.
    ```bash :show_vars +(defaults)
    source bin/colorize_env_vars.sh
    colorize_env_vars '' VAULT
    ```

The block sets the environment variable VAULT to "11".
When clicked, it adds the variable to the inherited code. It does not output.
    ```vars :[set_vault_11]
    VAULT: 11
    ```

# DOES NOT WORK 2024-07-20
## This does not evaluate the shell block.
::: Select below to trigger. If it prints "VAULT: 22", the shell block was processed.
The block sets the environment variable VAULT to "22". It requires block "show_vars". Notice block "show_vars" is called after the variable is set.
    ```vars :[set_with_show] +show_vars
    VAULT: 22
    ```

## This outputs the value before the variable is set.
The named block prints the environment variable VAULT. It requires block "set".
    ```bash :show_with_set +[set_vault_11]
    source bin/colorize_env_vars.sh
    colorize_env_vars '' VAULT
    ```
