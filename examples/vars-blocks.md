@import example-document-opts.md
```opts :(document_opts)
execute_in_own_window: false
output_execution_report: false
output_execution_summary: false
pause_after_script_execution: true
```
/The hidden block "(defaults)" sets the environment variable VAULT to "default" if it is unset.
/```bash :(defaults)
/: ${VAULT:=default}
/```
| Variable| Value
| -| -
| VAULT| ${VAULT}

::: Select below to trigger.
The block sets the environment variable VAULT to "11".
When clicked, it adds the variable to the inherited code.
    ```vars :[set_vault_11]
    VAULT: 11
    ```

::: Select below to trigger.
The block sets the environment variable VAULT to "22".
When clicked, it adds the variable to the inherited code.
    ```vars :[set_with_show]
    VAULT: 22
    ```
