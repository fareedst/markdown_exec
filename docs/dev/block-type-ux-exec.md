/ auto-load block, does not execute command to calculate
/ click block to calculate
```ux :[document_ux0]
init: ''
exec: basename $(pwd)
name: ux0
```
/ auto-load block and execute command to calculate
/ click block to recalculate
```ux :[document_ux1]
init: Unknown
exec: basename $(pwd)
name: ux1
```
/ auto-load block and execute command to calculate
/ click block to recalculate
```ux :[document_ux2]
exec: basename $(pwd)
name: ux2
```
/ required block defining a function used in exec
```bash :(bash3)
# function from bash3
val () { basename $(pwd) ; }
```
```ux :[document_ux3] +(bash3)
exec: val
name: ux3
```
/ default is computed
/ output of execution is validated/parsed
/ parsing is transformed
```ux :[document_ux4]
exec: basename $(pwd)
name: ux4
transform: "Xform: '%{name}'"
validate: |
  ^(?<name>.*)(_.*)$
```
@import bats-document-configuration.md