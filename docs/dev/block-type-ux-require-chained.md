/ UX blocks may requiring other UX blocks
```vars :(document_vars)
ENTITY: Pongo tapanuliensis,Pongo
```
```ux :[SPECIES] +[GENUS] +[NAME]
act: :echo
echo: "${ENTITY%%,*}"
force: true
init: false
name: SPECIES
```
```ux :[GENUS]
echo: "${ENTITY##*,}"
force: true
init: false
name: GENUS
```
```ux :[NAME] +[NAME2]
echo: "$SPECIES - $GENUS"
force: true
init: false
name: NAME
```
```ux :[NAME2]
echo: "$NAME"
force: true
init: false
name: NAME2
```
```opts :(document_opts)
menu_with_inherited_lines: true
```
@import bats-document-configuration.md