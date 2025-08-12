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
/
/ Each key in the echo hash is processed.
```ux
echo:
  Species2: Histiophryne psychedelica
  Genus2: Histiophryne
  Family2: Antennariidae
format: Psychedelic Frogfish
name: Common2
transform: :sort_chars
```
Species2: ${Species2}
Genus2: ${Genus2}
Family2: ${Family2}
@import bats-document-configuration.md