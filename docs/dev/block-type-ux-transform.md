:::
**Execution output has a trailing newline.**
```ux :[document_ux_transform_0]
exec: basename $(pwd)
name: Var0
```
$(echo -n "$Var0" | hexdump -v -e '16/1 " %02x"')
:::
**With validate and transform, output has no newline.**
```ux :[document_ux_transform_1]
exec: basename $(pwd)
name: Var1
transform: '%{name}'
validate: (?<name>.+)
```
$(echo -n "$Var1" | hexdump -v -e '16/1 " %02x"')
:::
**With transform `:chomp`, output has no newline.**
```ux :[document_ux_transform_2]
exec: basename $(pwd)
name: Var2
transform: :chomp
```
$(echo -n "$Var2" | hexdump -v -e '16/1 " %02x"')
:::
**With transform `:upcase`, output is in upper case w/ newline.**
```ux :[document_ux_transform_3]
exec: basename $(pwd)
name: Var3
transform: :upcase
```
$(echo -n "$Var3" | hexdump -v -e '16/1 " %02x"')
@import bats-document-configuration.md
```opts :(document_opts)
divider4_collapsible: false
screen_width: 80
table_center: false
```