/ v2025-02-08
| Variable| Value| Prompt
| -| -| -
/ auto-load default value
/ custom prompt
/ select list
/ default value
```ux :[document_ux_Species]
allowed:
- Pongo tapanuliensis
- Histiophryne psychedelica
- Phyllopteryx dewysea
default: Pongo tapanuliensis
name: Species
prompt: New species?
```
/ auto-load default value
/ cell text is prefixed Name/Value/Prompt
/ select list contains additional text
/ selected value is validated with named groups
/ selected value is transformed; named capture is prefixed Xform
```ux :[document_ux_Genus]
allowed:
- 1. Pongo
- 2. Histiophryne
- 3. Phyllopteryx
default: Pongo
menu_format: "| Name: %{name}| Value: ${%{name}}| Prompt: %{prompt}"
name: Genus
prompt: New genus?
transform: "Xform: '%{name}'"
validate: |
  ^\d+\. *(?<name>[^ ].*)$
```
/ default
/ auto-load default value
```ux :[document_ux_Family]
default: Hominidae
name: Family
```
@import bats-document-configuration.md
```opts :(document_opts)
menu_ux_row_format: '| %{name}| ${%{name}}| %{prompt}'
screen_width: 64
table_center: true
ux_auto_load_force_default: true
```