# Import Substitution Comprehensive Test

Tests enhanced @import ./functionality with text substitution using biological entity data.

## Basic Import (Backward Compatibility)

@import ./import-substitution-basic.md

## Raw Replacement - Simple Parameters

@import ./import-substitution-simple.md GENUS=Pongo FAMILY=Hominidae ORDER=Primates

## Raw Replacement - Quoted Values

@import ./import-substitution-quotes.md COMMON_NAME="Tapanuli Orangutan" SPECIES="Pongo tapanuliensis" LOCATION="Sumatra, Indonesia"

## Raw Replacement - Mixed Parameters

@import ./import-substitution-mixed.md COMMON_NAME="Psychedelic Frogfish" SPECIES="Histiophryne psychedelica" YEAR_DISCOVERED=2009 DEPTH="15-65 meters" HABITAT="Coral reefs"

## Raw Replacement - Numbers and Special Characters

@import ./import-substitution-special.md COMMON_NAME="Yeti Crab" YEAR_DISCOVERED=2005 DEPTH=2200 TEMPERATURE="2°C" LOCATION="Easter Island microplate"

## Raw Replacement - Long Scientific Names

@import ./import-substitution-long.md COMMON_NAME="Ecuadorian Glassfrog" SPECIES="Hyalinobatrachium yaku" GENUS=Hyalinobatrachium FAMILY=Centrolenidae ORDER=Anura CLASS=Amphibia

## Raw Replacement - Plant Data

@import ./import-substitution-plant.md COMMON_NAME="Spiny Dandelion" SPECIES="Taraxacum japonicum" KINGDOM=Plantae PHYLUM=Tracheophyta CLASS=Magnoliopsida

## Raw Replacement - Multiple Species Comparison

@import ./import-substitution-compare.md SPECIES1="Kiwa hirsuta" SPECIES2="Phyllopteryx dewysea" YEAR1=2005 YEAR2=2015 HABITAT1="Deep sea" HABITAT2="Coastal waters"

## Raw Replacement - Taxonomic Hierarchy

@import ./import-substitution-taxonomy.md DOMAIN=Eukaryota KINGDOM=Animalia PHYLUM=Chordata CLASS=Mammalia ORDER=Primates FAMILY=Hominidae GENUS=Homo SPECIES="Homo luzonensis"

## Raw Replacement - Research Data

@import ./import-substitution-research.md RESEARCHER="Dr. Matthew Leach" INSTITUTION="California Academy of Sciences" DISCOVERY_METHOD="Genetic analysis" SAMPLE_SIZE=47

## Export and Variables

@import ./import-substitution-export.md ORGANISM="Illacme tobini" DISCOVERY_YEAR=2016 LEG_COUNT=414 LOCATION="California" STATUS="Endemic"

Expected output shows proper text substitution with word boundary protection.
@import ./bats-document-configuration.md
```opts :(document_opts)
heading1_center: false
heading2_center: false
menu_include_imported_blocks: true
menu_include_imported_notes: true
screen_width: 64
```