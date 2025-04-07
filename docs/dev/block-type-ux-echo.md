/ This automatic block sets VAR and displays the current value in the menu.
```ux :[document_ux_VAR]
echo: $(basename `pwd`)
name: VAR
```
/ This block is not visible. Execute to display the inherited lines for testing.
```opts :(menu_with_inherited_lines)
menu_with_inherited_lines: true
```
/ This block is not visible. Execute to set a new value, displayed by the block above.
```ux :(VAR_has_count)
default: false
echo: $(basename `pwd` | wc -c)
force: false
name: VAR
```
/ This block is visible. Execute to set a new value, displayed by the block above.
```ux :[IAB_has_count]
default: false
echo: $VAR$VAR
name: IAB
```
@import bats-document-configuration.md