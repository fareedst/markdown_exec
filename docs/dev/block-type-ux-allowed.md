/ automatic block loads first allowed
```ux :[document_ux_SPECIES]
allowed:
- Pongo tapanuliensis
- Histiophryne psychedelica
name: SPECIES
```
/ automatic block loads first line in output of exec
```ux :[document_ux_GENUS]
allowed: :exec
exec: printf "Pongo\nHistiophryne psychedelica"
name: GENUS
```
/ executed block presents a menu of the allowed list
```ux :[FAMILY]
allowed:
- Hominidae
- Antennariidae
init: false
name: FAMILY
```
/ automatic block loads default value that is not in allowed list
```ux :[document_ux_ORDER]
allowed:
- Primates
- Lophiiformes
format: '%{name}: Click to select...'
name: ORDER
```
/ automatic block loads default value, not in allowed list from echo
```ux :[document_ux_CLASS]
allowed: :echo
format: Click to select...
echo: |
  Mammalia
  Actinopterygii
name: CLASS
```
/ executed block presents a menu of the lines in the output of exec
```ux :[YEAR_DISCOVERED]
allowed: :exec
init: false
prompt: ''
exec: echo "2017\n2009"
name: YEAR_DISCOVERED
```
/ automatic block presents a menu of the lines in the output of echo
```ux :[document_ux_NAME]
allowed: :echo
echo: |
  Tapanuli Orangutan
  Psychedelic Frogfish
name: NAME
```
/
/1. Tapanuli Orangutan
/
/* Species: Pongo tapanuliensis
/* Genus: Pongo
/* Family: Hominidae
/* Order: Primates
/* Class: Mammalia
/* Phylum: Chordata
/* Kingdom: Animalia
/* Domain: Eukaryota
/* Year: 2017
/
/2. Psychedelic Frogfish
/
/* Species: Histiophryne psychedelica
/* Genus: Histiophryne
/* Family: Antennariidae
/* Order: Lophiiformes
/* Class: Actinopterygii
/* Phylum: Chordata
/* Kingdom: Animalia
/* Domain: Eukaryota
/* Year: 2009
/
@import bats-document-configuration.md