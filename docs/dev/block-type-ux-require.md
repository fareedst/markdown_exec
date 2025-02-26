/ an automatic UX block requires a shell block and another UX block
``` :(shell)
ENTITY='Pongo tapanuliensis,Pongo'
```
```ux :[document_ux_SPECIES] +(shell) +[ux_GENUS]
default: :exec
exec: echo "${ENTITY%%,*}"
name: SPECIES
transform: :chomp
```
/ required ux block requires another
```ux :[ux_GENUS] +[ux_NAME]
default: :exec
exec: echo "${ENTITY##*,}"
name: GENUS
transform: :chomp
```
/ executed in context of prior ux blocks, uses their initial values
```ux :[ux_NAME]
default: :exec
exec: echo "$SPECIES - $GENUS"
name: NAME
transform: :chomp
```
/ executed after other ux blocks, uses their initial values
```ux :[document_ux_NAME2]
default: :exec
exec: echo "$NAME"
name: NAME2
transform: :chomp
```
@import bats-document-configuration.md