/ an UX block requires a shell block and another UX block
``` :(shell)
ENTITY='Pongo tapanuliensis,Pongo'
```
```ux :[SPECIES] +(shell) +(GENUS)
echo: "${ENTITY%%,*}"
name: SPECIES
```
/ required ux block requires another
```ux :(GENUS) +[NAME]
echo: "${ENTITY##*,}"
name: GENUS
readonly: true
```
/ executed in context of prior ux blocks, uses their values
```ux :[NAME]
echo: "$SPECIES - $GENUS"
name: NAME
readonly: true
```
@import bats-document-configuration.md