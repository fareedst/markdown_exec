/ Each key in the exec hash is processed.
```ux
exec:
  Species: echo 'Hydrodynastes bicinctus'
  Genus: echo Hydrodynastes
  Family: printf %s Colubridae
format: Cappuccino Snake
name: Common
transform: :upcase
```
__Species__
$(hexdump_format "$Species")
__Genus__
$(hexdump_format "$Genus")
__Family__
$(hexdump_format "$Family")
/
```ux :()
exec:
  Order: echo Squamata
  Class: printf %s Reptilia
  Phylum: printf %s Chordata
name: Common
transform: :delete_even_chars
```
__Order__
$(hexdump_format "$Order")
__Class__
$(hexdump_format "$Class")
__Phylum__
$(hexdump_format "$Phylum")
/
@import hexdump_format.md
@import bats-document-configuration.md
```opts :(document_opts)
screen_width: 64
```