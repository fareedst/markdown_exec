/ an automatic UX block requires a shell block and another UX block
``` :(shell)
ENTITY='Pongo tapanuliensis,Pongo'
```
```ux :[document_ux_SPECIES] +(shell) +[ux_GENUS]
default: :exec
exec: printf "${ENTITY%%,*}"
name: SPECIES
```
/ required ux block requires another
```ux :[ux_GENUS] +[ux_NAME]
default: :exec
exec: printf "${ENTITY##*,}"
name: GENUS
```
/ executed in context of prior ux blocks, uses their initial values
```ux :[ux_NAME]
default: :exec
exec: printf "$SPECIES - $GENUS"
name: NAME
```
/ executed after other ux blocks, uses their initial values
```ux :[document_ux_NAME2]
default: :exec
exec: printf "$NAME"
name: NAME2
```
@import bats-document-configuration.md