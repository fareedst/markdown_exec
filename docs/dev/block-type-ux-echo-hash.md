/ This automatic block sets multiple variables and displays the first variable.
```ux :[document_ux_BASENAME]
echo:
  BASENAME: "$(basename `pwd`)"
  DOCUMENTS: "${BASENAME%%_*}"
  OPERATION: "${BASENAME##*_}"
name: BASENAME
readonly: true
```
/ This block displays the second variable in the first block.
```ux :[DOCUMENTS]
init: false
name: DOCUMENTS
readonly: true
```
/ This block displays the third variable in the first block.
```ux :[OPERATION]
init: false
name: OPERATION
readonly: true
```
/ Multiple UX blocks to set many variables for a specific name.
```ux
init: false
echo:
  Species: Pongo tapanuliensis
  Genus: Pongo
  Family: Hominidae
  Order: Primates
  Class: Mammalia
  Phylum: Chordata
  Kingdom: Animalia
  Domain: Eukaryota
  Year_Discovered: 2017
menu_format: 'Load %{name}'
name: Tapanuli Orangutan
```
```ux
init: false
echo:
  Species: Histiophryne psychedelica
  Genus: Histiophryne
  Family: Antennariidae
  Order: Lophiiformes
  Class: Actinopterygii
  Phylum: Chordata
  Kingdom: Animalia
  Domain: Eukaryota
  Year_Discovered: 2009
menu_format: 'Load %{name}'
name: Psychedelic Frogfish
```
/ Start a table to format the output of UX blocks
| Variable| Value
| -| -
/ A read-only variable in a UX block in a table
```ux
init: false
menu_format: '| %{name}| ${%{name}}'
name: Species
readonly: true
```
/ A table row displays one variable in a table
| Genus| ${Genus}
/ An editable variable in a UX block in a table
```ux
init: false
menu_format: '| %{name}| ${%{name}}'
name: Family
```
@import bats-document-configuration.md
```opts :(document_opts)
# menu_ux_row_format: '| %{name}| ${%{name}}'
screen_width: 64
table_center: false
ux_auto_load_force_default: true
```