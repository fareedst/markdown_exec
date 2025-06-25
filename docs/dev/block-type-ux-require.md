/ This is an hidden shell block that is required by UX blocks.
``` :(shell)
ENTITY='Pongo tapanuliensis,Pongo'
```
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
/ This block is not visible. Execute to display the inherited lines for testing.
```opts :(menu_with_inherited_lines)
menu_with_inherited_lines: true
```
@import bats-document-configuration.md