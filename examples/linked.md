Demonstrate setting a variable interactively for use in generated scripts.

```opts :(document_options)
pause_after_script_execution: false
user_must_approve: false
```

::: Set VARIABLE to "A"

```link :set_to_A +(set_to_A)
block: display_variable
```

```bash :(set_to_A)
VARIABLE=A
```

::: Set VARIABLE to "B"

```link :set_to_B +(set_to_B)
block: display_variable
```

```bash :(set_to_B)
VARIABLE=B
```

::: Display value of VARIABLE

```bash :display_variable
source bin/colorize_env_vars.sh
colorize_env_vars '' VARIABLE
```
