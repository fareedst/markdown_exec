# current base name is: $(basename `pwd`)
:::: current base name is: $(basename `pwd`)
current base name is: $(basename `pwd`)
| current base name
| -
| $(basename `pwd`)
```bash
: notice the string is not expanded in Shell block types (names or body).
echo "current base name is now $(basename `pwd`)"
```
```link
load: file_$(basename `pwd`).sh
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