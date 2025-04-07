/ This is an hidden shell block that is required by UX blocks.
``` :(shell)
ENTITY='Pongo tapanuliensis,Pongo'
```
```ux +(shell)
echo: "${ENTITY%%,*}"
name: SPECIES
```
```ux +(shell)
echo: "${ENTITY##*,}"
name: GENUS
```
/ executed in context of prior ux blocks, uses their initial values
```ux
echo: "$SPECIES - $GENUS"
name: NAME
```
/ executed after other ux blocks, uses their initial values
```ux
echo: "$NAME"
name: NAME2
```
@import bats-document-configuration.md