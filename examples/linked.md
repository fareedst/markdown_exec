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

```link :set_to_A_eval +(set_to_A_eval)
block: display_variable
eval: true
```

```bash :(set_to_A_eval)
echo VARIABLE=A
```

::: Set VARIABLE to "B"

```link :set_to_B +(set_to_B)
block: display_variable
```

```bash :(set_to_B)
VARIABLE=B
```

```link :set_to_B_eval +(set_to_B_eval)
block: display_variable
eval: true
```

```bash :(set_to_B_eval)
echo VARIABLE=B
```

::: Display value of VARIABLE

```bash :display_variable
source bin/colorize_env_vars.sh
echo The current value of environment variable VARIABLE is now:
colorize_env_vars '' VARIABLE
```

```bash :(set_timestamp)
echo 'yyyymmdd? (default: today UTC) '; read -r yyyymmdd; [[ -z $yyyymmdd ]] && yyyymmdd="$(date -u +%y%m%d)"
echo "EC2_STACK_TS='$yyyymmdd'"
```
```link :request_input_and_inherit_output +(set_timestamp)
exec: true
```

::: Load file into inherited lines
Load (do not evaluate) and append to inherited lines.
```link :load1
load: examples/load1.sh
```
Load, evaluate, and append output to inherited lines.
```link :load2_eval
load: examples/load2.sh
eval: true
```
