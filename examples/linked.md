Demonstrate setting variable values interactively for use in generated scripts.

```opts :(document_options)
pause_after_script_execution: false
user_must_approve: false
```

::: Set variable ALPHA in a Vars block
For each environment variable named in block,
 append an inherited line that assigns the variable the specified value.
```vars :set_ALPHA_to_1_via_vars_block
ALPHA: 1
```

::: Set variable ALPHA in a Link block
For each environment variable in `vars`,
 append an inherited line that assigns the variable the specified value.
Subsequently, run the `display_variable_ALPHA` block.
```link :set_ALPHA_to_2_via_link_block_and_display
block: display_variable_ALPHA
vars:
  ALPHA: 2
```

Make the code in the required block `(bash_set_to_3)` into inherited lines.
Subsequently, run the `display_variable_ALPHA` block.
```bash :(bash_set_to_3)
ALPHA=3
```
```link :set_ALPHA_to_3_via_required_block_and_display +(bash_set_to_3)
block: display_variable_ALPHA
```

Evaluate the code in the required block `(bash_eval_set_to_4)` and
 save (transformed) output into inherited lines.
Subsequently, run the `display_variable_ALPHA` block.
```link :set_ALPHA_to_4_via_evaluated_required_block_and_display +(bash_eval_set_to_4)
eval: true
next_block: display_variable_ALPHA
```
```bash :(bash_eval_set_to_4)
echo 'ALPHA="4"'
```

::: Display value of ALPHA
```bash :display_variable_ALPHA
source bin/colorize_env_vars.sh
echo The current value of environment variable ALPHA is now:
colorize_env_vars '' ALPHA
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

::: Save and Load
Save inherited lines to a file.
```link :save1
save: tmp/save1.sh
```
Load inherited lines from a file.
Subsequently, run the `display_variables` block.
```link :load_saved
load: tmp/save1.sh
block: display_variables
```
Display variables ALPHA, var1, var2
```bash :display_variables
source bin/colorize_env_vars.sh
colorize_env_vars '' ALPHA var1 var2
```

Execute a script requiring input from the user.
Save the output setting TIMESTAMP into inherited lines.
Subsequently, run the `display_TIMESTAMP` block.
```bash :(input_timestamp)
if [[ -z $TIMESTAMP ]]; then
  default="$(date -u +%y%m%d)"
  echo "yymmdd? (default: $default / today UTC) "
  read -r TIMESTAMP
  [[ -z $TIMESTAMP ]] && TIMESTAMP="$(date -u +%y%m%d)"
fi
```
```bash :(inherit_timestamp)
echo "TIMESTAMP=\"$TIMESTAMP\""
```
```link :set_timestamp +(input_timestamp) +(inherit_timestamp)
exec: true
block: display_TIMESTAMP
```
```bash :display_TIMESTAMP
source bin/colorize_env_vars.sh
colorize_env_vars '' TIMESTAMP
```
