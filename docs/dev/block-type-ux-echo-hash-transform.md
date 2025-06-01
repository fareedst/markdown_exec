/ Each key in the echo hash is processed.
/
/ Each value is transformed.
```ux
echo:
  Species: Pongo tapanuliensis
  Genus: Pongo
format: Tapanuli Orangutan
name: Species
transform: :upcase
```
Species: ${Species}
Genus: ${Genus}
/
/ Each value is validated and transformed.
```ux
echo:
  Family: Hominidae
  Order: Primates
format: Tapanuli Orangutan
name: Family
transform: '%{capital}:%{name}'
validate: >
  ^(?<name>(?<capital>.?).*)$
```
Family: ${Family}
Order: ${Order}
//
// Each key in the exec hash is processed.
/```ux
/exec:
/  Species2: printf %s 'Histiophryne psychedelica'
/  Genus2: printf %s 'Histiophryne'
/format: Psychedelic Frogfish
/name: Species2
/transform: :downcase
/```
/Species2: ${Species2}
/Genus2: ${Genus2}
@import bats-document-configuration.md