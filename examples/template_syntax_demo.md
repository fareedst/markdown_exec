# Template Syntax Demo

This file shows the primary **raw replacement** mode and optional template delimiter modes using biological entity data.

## Primary Mode: Raw Replacement (Default)

@import imports/template_vars.md COMMON_NAME="Mythical Monkey" SPECIES="Cercopithecus lomamiensis" GENUS=Cercopithecus FAMILY=Cercopithecidae ORDER=Primates CLASS=Mammalia YEAR_DISCOVERED=2012

## Template Delimiter Mode (Optional)

@import imports/template_mustache.md COMMON_NAME="Ecuadorian Glassfrog" SPECIES="Hyalinobatrachium yaku" GENUS=Hyalinobatrachium FAMILY=Centrolenidae ORDER=Anura CLASS=Amphibia YEAR_DISCOVERED=2017

*Note: Template delimiter mode requires `use_template_delimiters: true` configuration*

## Complex Example - Plant Species

@import imports/mixed_template.md COMMON_NAME="Spiny Dandelion" SPECIES="Taraxacum japonicum" GENUS=Taraxacum FAMILY=Asteraceae ORDER=Asterales CLASS=Magnoliopsida YEAR_DISCOVERED=2022

## How It Works

- **Raw replacement** (default): Placeholders are just key names like `COMMON_NAME`, `SPECIES`, `GENUS`
- **Template delimiters** (optional): Placeholders use `${SPECIES}` or `{{GENUS}}` syntax
- Raw replacement is simpler and more direct
- Template delimiters provide explicit boundaries when needed for taxonomic data 