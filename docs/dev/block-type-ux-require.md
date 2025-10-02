```ux +(shell)
echo: "${ENTITY%%,*}"
force: true
name: SPECIES
```
```ux +(shell)
echo: "${ENTITY##*,}"
force: true
name: GENUS
```
/ executed in context of prior ux blocks, uses their initial values
```ux
echo: "$SPECIES - $GENUS"
force: true
name: NAME
```
/ executed after other ux blocks, uses their initial values
```ux
echo: "$NAME"
force: true
name: NAME2
```
/
/ This is a hidden shell block that is required by a UX block.
/ All shell blocks required by a UX block are collected in a sequence
/ that is the context for the evaluation of the expressions in the UX block.
``` :(shell)
ENTITY='Pongo tapanuliensis,Pongo'
```
/
/ This block is not visible. Execute to display the inherited lines for testing.
```opts :(menu_with_inherited_lines)
menu_with_inherited_lines: true
```
@import bats-document-configuration.md