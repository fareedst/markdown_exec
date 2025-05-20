/ a UX block requires a shell block and another UX block
``` :(shell)
ENTITY='Pongo tapanuliensis,Pongo'
```
```ux :[SPECIES] +(shell) +(GENUS)
echo: "${ENTITY%%,*}"
init: false
name: SPECIES
```
/ required ux block requires another
```ux :(GENUS) +[NAME]
echo: "${ENTITY##*,}"
init: false
name: GENUS
readonly: true
```
/ executed in context of prior ux blocks, uses their values
```ux :[NAME]
echo: "$SPECIES - $GENUS"
init: false
name: NAME
readonly: true
```
@import bats-document-configuration.md