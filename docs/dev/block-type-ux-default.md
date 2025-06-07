/ v2025-02-08
/ name only
```ux
name: v1
```
/ name and default
/ transform and validate options not applied to default
```ux
init: 11
name: v2
```
/ name and default; auto-load
/ prompt option is ignored during auto-load
```ux :[document_ux_v3]
echo: 12
name: v3
```
/ name, default, exec; auto-load static
```ux :[document_ux_v4]
init: 21
exec: basename $(pwd)
name: v4
```
/ name, default, exec; auto-load executed `basename $(pwd)`
/ allowed is ignored by exec
```ux :[document_ux_v5]
exec: basename $(pwd)
name: v5
```
/ name, default, allowed; auto-load static default
```ux :[document_ux_v6]
allowed:
- 31
- 32
- 33
name: v6
```
@import bats-document-configuration.md
```opts :(document_opts)
menu_ux_row_format: '%{name} = ${%{name}}'
ux_auto_load_force_default: true
```