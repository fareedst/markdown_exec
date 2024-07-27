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
