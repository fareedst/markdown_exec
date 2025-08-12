A single named variable is set **automatically** as the output of the exec string.
```ux
exec: echo 'Yeti Crab'
name: Common_Name
```
Common_Name=${Common_Name}
$(hexdump_format "$Common_Name")



Multiple variables are set **automatically** as the output of each exec string.
One variable is temporary/not stored to inherited lines but available for calculations within the block.
/ Substring Extraction using POSIX parameter expansion.
```ux
exec:
  __D: >-
    echo 'Domain: Eukaryota'
  Domain: >-
    echo "${__D:7,9}"
name: Domain
```
__D=${__D}
Domain=${Domain}
$(hexdump_format "$Domain")



A single named variable is set **interactively** as the output of the exec string.
```ux :[Year_Discovered]
exec: echo 2005
init: false
name: Year_Discovered
```
Year_Discovered=${Year_Discovered}
$(hexdump_format "$Year_Discovered")



Multiple variables are set **interactively** as the output of the exec string.
/ String Replacement
```ux :[Genus]
exec:
  Species: echo 'Kiwa hirsuta'
  Genus: echo "${Species/ hirsuta/}"
init: false
name: Genus
```
Species=${Species}
$(hexdump_format "$Species")
Genus=${Genus}
$(hexdump_format "$Genus")



A single named variable is set **automatically** as the first line of the output of the first element in the echo hash.
```ux
allow: :echo
echo:
  __K: |
    Animalia
    Animalia2
  __P: |
    Arthropoda
    Arthropoda2
name: Kingdom
```
Kingdom=${Kingdom}
$(hexdump_format "$Kingdom")



**A single named variable is set automatically** as the first line of the output of the first element in the exec hash.
```ux
allow: :exec
exec:
  __C: |
    echo Malacostraca
    echo Malacostraca2
  __P: |
    echo Arthropoda
    echo Arthropoda2
name: Class
```
Class=${Class}
$(hexdump_format "$Class")



@import hexdump_format.md
@import bats-document-configuration.md
```opts :(document_opts)
screen_width: 64
```