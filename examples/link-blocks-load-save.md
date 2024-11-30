::: Load file into inherited lines
Load (do not evaluate) and append to inherited lines.
```link :load1
load: docs/dev/load1.sh
```
Load, evaluate, and append output to inherited lines.
```link :load2_eval
load: examples/load2.sh
eval: true
```

::: Load file into inherited lines and switch document
Load (do not evaluate) and append to inherited lines and switch document.
```link :load_from_file_link_and_show
file: examples/linked_show.md
load: docs/dev/load1.sh
```

::: Save and Load
Save inherited lines to a file.
```link :save1
save: tmp/save1.sh
```
Load inherited lines from a file.
```link :load_saved
load: tmp/save1.sh
```

| Variable| Value
| -| -
| ALPHA| ${ALPHA}
| var1| ${var1}
| var2| ${var2}

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
