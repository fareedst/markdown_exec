/ a UX block that requires a shell block and another UX block
``` :(shell)
ENTITY='Pongo tapanuliensis,Pongo'
```
```ux :[SPECIES] +(shell) +(GENUS)
act: :echo
echo: "${ENTITY%%,*}"
init: false
name: SPECIES
```
/ required ux block requires another
```ux :(GENUS) +[NAME]
echo: "${ENTITY##*,}"
init: false
name: GENUS
```
/ executed in context of prior ux blocks, uses their values
```ux :[NAME]
echo: "$SPECIES - $GENUS"
init: false
name: NAME
```
@import bats-document-configuration.md