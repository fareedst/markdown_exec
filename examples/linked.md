Demonstrate setting variable values interactively for use in generated scripts.

```opts :(document_options)
menu_with_inherited_lines: true
pause_after_script_execution: false
user_must_approve: false
```

```link :missing_block
block: (display_variable)
eval: true
```
Block name with all chars.
/ !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
/ ¡¢£¤¥¦§¨©ª«¬®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ
```link :!"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
file: examples/linked2.md
block: show_vars
vars:
  page2_var_via_environment: for_page2_from_page1_via_current_environment
```
```link :¡¢£¤¥¦§¨©ª«¬®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ
file: examples/linked2.md
block: show_vars
vars:
  page2_var_via_environment: for_page2_from_page1_via_current_environment
```
Block with no title is displayed correctly in a single line (for a Bash comment).
```link
file: examples/linked2.md
block: show_vars
vars:
  page2_var_via_environment: for_page2_from_page1_via_current_environment
```
Spaces in variable value are unchanged.
```link :link_with_vars_with_spaces
vars:
  test: "1 2 3"
```

::: Set variable ALPHA in a Vars block
For each environment variable named in block,
 append an inherited line that assigns the variable the specified value.
```vars :[set_ALPHA_to_1_via_vars_block]
ALPHA: 1
```

::: Set variable ALPHA in a Link block
For each environment variable in `vars`,
 append an inherited line that assigns the variable the specified value.
Subsequently, run the `display_variable_ALPHA` block.
```link :[set_ALPHA_to_2_via_link_block_and_display]
block: display_variable_ALPHA
vars:
  ALPHA: 2
```

Make the code in the required block `(bash_set_to_3)` into inherited lines.
Subsequently, run the `display_variable_ALPHA` block.
```bash :(bash_set_to_3)
ALPHA=3
```
```link :[set_ALPHA_to_3_via_required_block_and_display] +(bash_set_to_3)
block: display_variable_ALPHA
```

Evaluate the code in the required block `(bash_eval_set_to_4)` and
 save (transformed) output into inherited lines.
Subsequently, run the `display_variable_ALPHA` block.
```link :[set_ALPHA_to_4_via_evaluated_required_block_and_display] +(bash_eval_set_to_4)
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

::: Load file into inherited lines and switch document
Load (do not evaluate) and append to inherited lines and switch document.
```link :load_from_file_link_and_show
block: show_vars
file: examples/linked_show.md
load: examples/load1.sh
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

::: Load file matching glob pattern into inherited lines
Load (do not evaluate) and append to inherited lines.
```link :load_glob_load1*
load: examples/load1*.sh
```
```link :load_glob_load*
load: examples/load*.sh
```
```link :load_glob_fail
load: examples/fail*
```
```link :load_glob_with_format
load: "%{home}/examples/load*.sh"
```
```link :save_glob_load*
save: examples/*.sh
```
```link :save_glob_*
save: examples/*.sh
```
```link :load_glob_*
load: examples/*.sh
```
