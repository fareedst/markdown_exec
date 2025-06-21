# Import with Text Substitution Demo

This demonstrates the new enhanced `@import` functionality that supports text substitution parameters with **raw replacement** as the primary mode, using biological entity data.

## Primate Classification Examples

@import imports/organism_template.md COMMON_NAME="Tapanuli Orangutan" SPECIES="Pongo tapanuliensis" GENUS=Pongo FAMILY=Hominidae ORDER=Primates CLASS=Mammalia YEAR_DISCOVERED=2017

@import imports/organism_template.md COMMON_NAME="Homo luzonensis" SPECIES="Homo luzonensis" GENUS=Homo FAMILY=Hominidae ORDER=Primates CLASS=Mammalia YEAR_DISCOVERED=2019

## Marine Life Classification

@import imports/organism_template.md COMMON_NAME="Yeti Crab" SPECIES="Kiwa hirsuta" GENUS=Kiwa FAMILY=Kiwaidae ORDER=Decapoda CLASS=Malacostraca YEAR_DISCOVERED=2005

The imported template file uses **raw text placeholders** (just the key name) that get replaced with the biological data specified in the @import line.

## Primary Mode: Raw Replacement

By default, template placeholders are just the key names without any delimiters:

```
Common Name: COMMON_NAME
Species: SPECIES  
Genus: GENUS
Family: FAMILY
```

Gets transformed to:

```
Common Name: Tapanuli Orangutan
Species: Pongo tapanuliensis
Genus: Pongo
Family: Hominidae
```

## Usage Examples

Here are different ways to specify biological data:

- Simple values: `@import imports/organism_template.md GENUS=Pongo CLASS=Mammalia`
- Quoted values with spaces: `@import imports/organism_template.md COMMON_NAME="Psychedelic Frogfish"`  
- Multiple taxonomic parameters: `@import imports/organism_template.md SPECIES="Pongo tapanuliensis" GENUS=Pongo FAMILY=Hominidae`
- Mixed quoting: `@import imports/organism_template.md COMMON_NAME='Ruby Seadragon' SPECIES="Phyllopteryx dewysea" GENUS=Phyllopteryx`

## Optional: Template Delimiters

For cases where you need `${}` or `{{}}` style placeholders, you can use the template delimiter mode (requires code configuration). 