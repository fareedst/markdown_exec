# Raw Replacement Demo

This demonstrates the primary **raw replacement** mode of the enhanced `@import` functionality using biological entity data.

## Tapanuli Orangutan Classification

@import imports/organism_template.md COMMON_NAME="Tapanuli Orangutan" SPECIES="Pongo tapanuliensis" GENUS=Pongo FAMILY=Hominidae ORDER=Primates CLASS=Mammalia YEAR_DISCOVERED=2017

## Psychedelic Frogfish Classification

@import imports/organism_template.md COMMON_NAME="Psychedelic Frogfish" SPECIES="Histiophryne psychedelica" GENUS=Histiophryne FAMILY=Antennariidae ORDER=Lophiiformes CLASS=Actinopterygii YEAR_DISCOVERED=2009

## Ruby Seadragon Classification

@import imports/organism_template.md COMMON_NAME="Ruby Seadragon" SPECIES="Phyllopteryx dewysea" GENUS=Phyllopteryx FAMILY=Syngnathidae ORDER=Syngnathiformes CLASS=Actinopterygii YEAR_DISCOVERED=2015

## How It Works

In raw replacement mode (the default), placeholders in template files are just the key names:

- `COMMON_NAME` gets replaced with the actual common name
- `SPECIES` gets replaced with the scientific species name  
- `GENUS` gets replaced with the taxonomic genus
- `FAMILY` gets replaced with the taxonomic family
- etc.

This is different from template delimiter modes that use `${SPECIES}` or `{{GENUS}}`.

## Benefits of Raw Replacement

1. **Simple syntax** - No need for special delimiters
2. **Clean templates** - Templates are more readable
3. **Direct replacement** - What you see is what gets replaced
4. **Scientific data friendly** - Works well with taxonomic classifications

## Word Boundary Protection

Raw replacement uses word boundaries, so:

- `SPECIES` in "Species: SPECIES" gets replaced ✓
- `SPECIES` in "SUBSPECIES=unknown" does NOT get replaced ✓
- Partial matches are avoided automatically 