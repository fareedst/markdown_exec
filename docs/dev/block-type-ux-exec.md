/ auto-load block and execute command to calculate
/ click block to recalculate
```ux :[document_ux1]
default: Unknown
exec: basename $(pwd)
name: Now1
```
/ auto-load block and execute command to calculate
/ click block to recalculate
```ux :[document_ux2]
default: :exec
exec: basename $(pwd)
name: Now2
```
/ required block defining a function used in exec
```bash :(bash3)
# function from bash3
val () { basename $(pwd) ; }
```
```ux :[document_ux3] +(bash3)
default: :exec
exec: val
name: Now3
```
/ default is computed
/ output of execution is validated/parsed
/ parsing is transformed
```ux :[document_ux4]
default: :exec
exec: basename $(pwd)
name: Now4
transform: "Xform: '%{name}'"
validate: |
  ^(?<name>.*)(_.*)$
```
@import bats-document-configuration.md