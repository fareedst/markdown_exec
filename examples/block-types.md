# Demonstrate fenced code block types

Default to Bash block type.
    ```
    echo "species"
    ```

Specified block types.
    Bash
        ```bash
        echo "genus"
        ```
    YAML
        ```yaml
        ---
        a: 1
        ```

@import example-document-opts.md
```opts :(document_opts)
bash_only: false
execute_in_own_window: false
output_execution_report: false
output_execution_summary: false
pause_after_script_execution: true
```