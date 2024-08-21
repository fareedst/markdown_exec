# Demonstrate link blocks set variables
```opts :(document_options)
execute_in_own_window: false
menu_with_inherited_lines: true
output_execution_report: false
output_execution_summary: false
pause_after_script_execution: true
```

## Demonstrate a link block that sets a variable
::: Select below to trigger. If it prints "VARIABLE1: 1", the Link block was processed.
The hidden block "(print-VARIABLE1)" is required below. It prints variable "VARIABLE1".
```bash :(print-VARIABLE1)
source bin/colorize_env_vars.sh
colorize_env_vars '' VARIABLE1
```
The block sets VARIABLE1 and requires hidden block "(print-VARIABLE1)".
For each environment variable in `vars`, append an inherited line that assigns the variable the specified value.
    ```link
    block: (print-VARIABLE1)
    vars:
      VARIABLE1: 1
    ```

## Demonstrate a link block that requires a shell block that sets a variable
This block "[bash_set_to_3]" is required below. It sets the variable "ALPHA".
    ```bash :[bash_set_to_3]
    ALPHA=3
    ```
::: Select below to trigger. If it prints "ALPHA: 3", the Link block was processed.
These blocks require the *code* of the named shell block.
    ```link +[bash_set_to_3]
    block: "(display_variable_ALPHA)"
    ```
    ```link +[bash_set_to_3]
    next_block: "(display_variable_ALPHA)"
    ```

This block "[bash_set_to_4]" is required below. It prints a command that sets the variable "ALPHA".
    ```bash :[bash_set_to_4]
    echo "ALPHA=4"
    ```
::: Select below to trigger. If it prints "ALPHA: 4", the Link block was processed.
These blocks require the *output* of the execution of the code in the named shell block.
    ```link +[bash_set_to_4]
    eval: true
    block: "(display_variable_ALPHA)"
    ```
    ```link +[bash_set_to_4]
    eval: true
    next_block: "(display_variable_ALPHA)"
    ```
```bash :(display_variable_ALPHA)
source bin/colorize_env_vars.sh
colorize_env_vars '' ALPHA
```
