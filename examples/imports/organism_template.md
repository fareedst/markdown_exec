# COMMON_NAME Classification

**Common Name:** COMMON_NAME  
**Species:** SPECIES  
**Genus:** GENUS  
**Family:** FAMILY  
**Order:** ORDER  
**Class:** CLASS  
**Year Discovered:** YEAR_DISCOVERED

## Taxonomic Classification

```bash
# Biological classification data
export COMMON_NAME="COMMON_NAME"
export SPECIES="SPECIES"
export GENUS="GENUS"
export FAMILY="FAMILY"
export ORDER="ORDER"
export CLASS="CLASS"
export YEAR_DISCOVERED="YEAR_DISCOVERED"

echo "Organism: COMMON_NAME"
echo "Scientific name: SPECIES"
echo "Discovered in: YEAR_DISCOVERED"
```

## Classification Hierarchy

```yaml
organism:
  common_name: COMMON_NAME
  scientific_name: SPECIES
  taxonomy:
    genus: GENUS
    family: FAMILY
    order: ORDER
    class: CLASS
  discovery_year: YEAR_DISCOVERED
```

Biological organism template using raw replacement for taxonomic data. 