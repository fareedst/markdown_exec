# Evidence
## SOURCE is: ${SOURCE}
:::: SOURCE is: ${SOURCE}
SOURCE is: ${SOURCE}
| SOURCE
| -
| ${SOURCE}
```bash :name_with_${SOURCE}_in_name
# notice the string is not expanded by the shell
echo "SOURCE is now ${SOURCE}"
```
```link
load: file_${SOURCE}.sh
```
# Sources
```link :(LINK_LOAD_SOURCE)
load: temp_variable_expansion.sh
```
```link :(LINK_VARS_SOURCE)
vars:
  SOURCE: Link block
```
```vars :(VARS_SOURCE)
SOURCE: Vars block
```
@import bats-document-configuration.md
```opts :(document_opts)
heading1_center: false
heading2_center: false
heading3_center: false
menu_final_divider:
menu_for_saved_lines: false
menu_initial_divider:
menu_vars_set_format:
table_center: false
```