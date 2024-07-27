```opts :(document_options)
execute_in_own_window: false
pause_after_script_execution: true
save_executed_script: true
saved_script_folder: ../mde_logs
```
Pass-through arguments after "--" to the executed script.

A block can expect arguments to receive all arguments to MDE after "--".

For `mde examples/pass-through.md output_arguments -- 1 23`,
this block outputs:

        ARGS: 1 23

::: Test
```bash
mde examples/pass-through.md output_arguments -- 1 23
```

::: These options toggle the use of a separate window.
```opts
execute_in_own_window: true
```
```opts
execute_in_own_window: false
```

::: This block will output any command line arguments after "--".
```bash :output_arguments
echo "ARGS: $*"
```
