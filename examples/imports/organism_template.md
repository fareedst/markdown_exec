# COMMON_NAME Classification

**Common Name:** ${COMMON_NAME}
**Species:** ${PLAIN_SPECIES}
**Genus:** ${GENUS}
**Family:** ${FAMILY}
**Order:** ${ORDER}
**Class:** ${CLASSIFICATION_TYPE}
**Year Discovered:** ${YEAR_DISCOVERED}

## Parameter Processing Examples

__Raw Literal (=)__
- Report title: `REPORT_TITLE`
- Fixed classification: `CLASSIFICATION_TYPE`

__Force-Quoted Literal (:q=)__
- Quoted species name: `QUOTED_SPECIES`
- Quoted common name: `QUOTED_NAME`

__Variable Reference (:v=)__
- Common name from variable: `BASE_NAME`
- Discovery year from document: `DOC_YEAR`

__Evaluated Expression (:e=)__
- Generated filename: `GENERATED_FILE`
- Formatted description: `DESCRIPTION`

__Command Substitution (:c=)__
- Current timestamp: `TIMESTAMP`
- Latest report file: `LATEST_REPORT`

## Taxonomic Classification

```bash
# Biological classification data with different parameter types
export common_name=COMMON_NAME
export species="PLAIN_SPECIES"
export genus="GENUS"
export family="FAMILY"
export order="ORDER"
export class="CLASSIFICATION_TYPE"
export year_discovered="YEAR_DISCOVERED"

# Examples of parameter processing types
echo "Report: REPORT_TITLE"
echo "Quoted species: QUOTED_SPECIES"
echo "Quoted name: QUOTED_NAME"
echo "Base name from var: BASE_NAME"
echo "Doc year from var: DOC_YEAR"
echo "Generated file: GENERATED_FILE"
echo "Description: DESCRIPTION"
echo "Timestamp: TIMESTAMP"
echo "Latest report: LATEST_REPORT"

echo "Organism: $common_name"
echo "Scientific name: $species"
echo "Discovered in: $year_discovered"
echo "Classification: $class"
```

## Classification Hierarchy

organism:
  common_name: ${COMMON_NAME}
  scientific_name: ${PLAIN_SPECIES}
  taxonomy:
    genus: ${GENUS}
    family: ${FAMILY}
    order: ${ORDER}
    class: ${CLASSIFICATION_TYPE}
  discovery_year: ${YEAR_DISCOVERED}
  
metadata:
  report_title: ${REPORT_TITLE}
  classification_type: ${CLASSIFICATION_TYPE}
  quoted_species: ${QUOTED_SPECIES}
  quoted_name: ${QUOTED_NAME}
  base_name: ${BASE_NAME}
  doc_year: ${DOC_YEAR}
  generated_file: ${GENERATED_FILE}
  description: ${DESCRIPTION}
  timestamp: ${TIMESTAMP}
  latest_report: ${LATEST_REPORT}

## Generated Documentation

**Report:** ${REPORT_TITLE}  
**Classification:** ${CLASSIFICATION_TYPE}  
**Quoted Species:** ${QUOTED_SPECIES}  
**Quoted Name:** ${QUOTED_NAME}  
**Base Name:** ${BASE_NAME}  
**Doc Year:** ${DOC_YEAR}  
**Generated File:** ${GENERATED_FILE}  
**Description:** ${DESCRIPTION}  
**Timestamp:** ${TIMESTAMP}  
**Latest Report:** ${LATEST_REPORT}  

Biological organism template demonstrating all five parameter processing modes: raw literal (=), force-quoted literal (:q=), variable reference (:v=), evaluated expression (:e=), and command substitution (:c=). 