:::
**Execution output has a trailing newline.**
```ux :[document_ux_transform_0]
exec: basename $(pwd)
name: Var0
```
$(print_bytes "$Var0")
:::
**With validate and transform, output has no newline.**
```ux :[document_ux_transform_1]
exec: basename $(pwd)
name: Var1
transform: '%{name}'
validate: (?<name>.+)
```
$(print_bytes "$Var1")
:::
**With transform `:chomp`, output has no newline.**
```ux :[document_ux_transform_2]
exec: basename $(pwd)
name: Var2
transform: :chomp
```
$(print_bytes "$Var2")
:::
**With transform `:upcase`, output is in upper case w/ newline.**
```ux :[document_ux_transform_3]
exec: basename $(pwd)
name: Var3
transform: :upcase
```
$(print_bytes "$Var3")
@import bats-document-configuration.md
@import print_bytes.md
```opts :(document_opts)
divider4_collapsible: false
screen_width: 80
table_center: false
```