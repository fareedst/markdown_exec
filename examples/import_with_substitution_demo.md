# Import with Text Substitution Demo

This demonstrates the enhanced `@import` functionality that supports **five types of parameter processing** for flexible template substitution, using biological entity data as examples.

## Parameter Processing Types

__1. Raw Literal (=)__
Use `=` for raw literal replacement (baseline behavior).

__2. Force-Quoted Literal (:q=)__
Use `:q=` to force-quote the value with double quotes.

__3. Variable Reference (:v=)__
Use `:v=` to substitute with the value of a variable from the main document.

__4. Evaluated Expression (:e=)__
Use `:e=` for printf-safe string expressions with variable expansion.

__5. Command Substitution (:c=)__
Use `:c=` to execute a command and use its output.

## Comprehensive Example

@import imports/organism_template.md COMMON_NAME:q="Tapanuli Orangutan" PLAIN_SPECIES:q="Pongo tapanuliensis" GENUS:v=orangutan_genus FAMILY:q="Hominidae" ORDER:q="Primates" CLASS:q="Mammalia" YEAR_DISCOVERED:v=discovery_year_2017 REPORT_TITLE:q="Primate Species Report" CLASSIFICATION_TYPE:q="Endangered Species" QUOTED_SPECIES:q="Pongo tapanuliensis" QUOTED_NAME:q="Tapanuli Orangutan" BASE_NAME:v=orangutan_base DOC_YEAR:v=discovery_year_2017 GENERATED_FILE:e="report-${COMMON_NAME// /_}-$(date +%Y%m%d).md" DESCRIPTION:e="Classification report for ${COMMON_NAME} (${PLAIN_SPECIES})" TIMESTAMP:c="date '+%Y-%m-%d %H:%M:%S'" LATEST_REPORT:c="find reports -name '*.md' -type f -exec ls -t {} + | head -n 1"

## Parameter Type Examples

### Example 1: Mixed Parameter Types

@import imports/organism_template.md COMMON_NAME:q="Homo luzonensis" PLAIN_SPECIES:q="Homo luzonensis" GENUS:v=homo_genus FAMILY:q="Hominidae" ORDER:q="Primates" CLASS:q="Mammalia" YEAR_DISCOVERED:v=discovery_year_2019 REPORT_TITLE:q="Human Ancestor Documentation" CLASSIFICATION_TYPE:q="Extinct Hominin" QUOTED_SPECIES:q="Homo luzonensis" QUOTED_NAME:q="Homo luzonensis" BASE_NAME:v=homo_base DOC_YEAR:v=discovery_year_2019 GENERATED_FILE:e="homo-luzonensis-$(date +%Y%m%d).md" DESCRIPTION:e="Recent human ancestor discovered in ${YEAR_DISCOVERED}" TIMESTAMP:c="date -u '+%Y-%m-%dT%H:%M:%SZ'" LATEST_REPORT:c="ls -t *.md | head -n 1"

### Example 2: Marine Life with Command Evaluation

@import imports/organism_template.md COMMON_NAME:q="Yeti Crab" PLAIN_SPECIES:q="Kiwa hirsuta" GENUS:v=kiwa_genus FAMILY:q="Kiwaidae" ORDER:q="Decapoda" CLASS:q="Malacostraca" YEAR_DISCOVERED:v=discovery_year_2005 REPORT_TITLE:q="Deep Sea Species Catalog" CLASSIFICATION_TYPE:q="Marine Arthropod" QUOTED_SPECIES:q="Kiwa hirsuta" QUOTED_NAME:q="Yeti Crab" BASE_NAME:v=kiwa_base DOC_YEAR:v=discovery_year_2005 GENERATED_FILE:e="marine-${COMMON_NAME// /-}-report.md" DESCRIPTION:e="Deep sea crab species found near hydrothermal vents" TIMESTAMP:c="date '+%B %d, %Y at %I:%M %p'" LATEST_REPORT:c="find . -name '*marine*.md' -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-"

The imported template file uses **parameter placeholders** that get replaced based on the processing type specified in the @import directive.

## Parameter Processing Syntax Reference

__1. Raw Literal (=)__
```
PARAM=value
```
**Usage:** Replace `PARAM` with `value` (baseline behavior).

**Examples:**
```
COMMON_NAME="Tapanuli Orangutan"
FAMILY="Hominidae"
CLASSIFICATION_TYPE=Endangered
```

__2. Force-Quoted Literal (:q=)__
```
PARAM:q=value
```
**Usage:** Replace `PARAM` with `"value"` (automatically adds double quotes).

**Examples:**
```
QUOTED_SPECIES:q=Pongo tapanuliensis
QUOTED_NAME:q=Tapanuli Orangutan
```

__3. Variable Reference (:v=)__
```
PARAM:v=VAR_NAME
```
**Usage:** Replace `PARAM` with `${VAR_NAME}` from the main document.

**Examples:**
```
GENUS:v=orangutan_genus
YEAR_DISCOVERED:v=discovery_year_2017
```

__4. Evaluated Expression (:e=)__
```
PARAM:e=expr
```
**Usage:** Replace `PARAM` with `$(printf %s "expr")` (printf-safe string processing).

**Examples:**
```
GENERATED_FILE:e="report-${COMMON_NAME// /_}-$(date +%Y%m%d).md"
DESCRIPTION:e="Classification report for ${COMMON_NAME} (${PLAIN_SPECIES})"
FILENAME:e="${GENUS,,}-${PLAIN_SPECIES,,}.md"
```

__5. Command Substitution (:c=)__
```
PARAM:c=command
```
**Usage:** Replace `PARAM` with `$(command)` (raw command execution).

**Examples:**
```
TIMESTAMP:c="date '+%Y-%m-%d %H:%M:%S'"
LATEST_REPORT:c="ls -t *.md | head -n 1"
FILE_COUNT:c="find . -name '*.md' | wc -l"
CURRENT_USER:c="whoami"
```

## Complete Parameter Processing Example

```
@import imports/organism_template.md COMMON_NAME="Tapanuli Orangutan" PLAIN_SPECIES="Pongo tapanuliensis" GENUS:v=orangutan_genus FAMILY="Hominidae" ORDER="Primates" CLASS="Mammalia" YEAR_DISCOVERED:v=discovery_year_2017 REPORT_TITLE="Primate Species Report" CLASSIFICATION_TYPE="Endangered Species" QUOTED_SPECIES:q="Pongo tapanuliensis" QUOTED_NAME:q="Tapanuli Orangutan" BASE_NAME:v=orangutan_base DOC_YEAR:v=discovery_year_2017 GENERATED_FILE:e="report-${COMMON_NAME// /_}-$(date +%Y%m%d).md" DESCRIPTION:e="Classification report for ${COMMON_NAME} (${PLAIN_SPECIES})" TIMESTAMP:c="date '+%Y-%m-%d %H:%M:%S'" LATEST_REPORT:c="find reports -name '*.md' -type f -exec ls -t {} + | head -n 1"
```

## Template Placeholder Format

Template placeholders are raw key names without delimiters:

```markdown
**Common Name:** COMMON_NAME
**Species:** PLAIN_SPECIES
**Quoted Species:** QUOTED_SPECIES
**Quoted Name:** QUOTED_NAME
**Base Name:** BASE_NAME
**Doc Year:** DOC_YEAR
**Report:** REPORT_TITLE
**Generated File:** GENERATED_FILE
**Description:** DESCRIPTION
**Timestamp:** TIMESTAMP
**Latest Report:** LATEST_REPORT
```

Gets transformed based on parameter processing type:

```markdown
**Common Name:** Tapanuli Orangutan
**Species:** Pongo tapanuliensis
**Quoted Species:** "Pongo tapanuliensis"
**Quoted Name:** "Tapanuli Orangutan"
**Base Name:** Great Ape
**Doc Year:** 2017
**Report:** Primate Species Report
**Generated File:** report-Tapanuli_Orangutan-20240115.md
**Description:** Classification report for Tapanuli Orangutan (Pongo tapanuliensis)
**Timestamp:** 2024-01-15 14:30:22
**Latest Report:** reports/primates-2024.md
```

## Rationale for Syntax Design

- **`=`** → Raw literal (baseline behavior, simple and clean)
- **`:q=`** → Force-quoted literal (`:q` clearly indicates quoting)
- **`:v=`** → Variable reference (`:v` indicates variable lookup)
- **`:e=`** → Evaluated expression (`:e` indicates expression evaluation with printf safety)
- **`:c=`** → Command substitution (`:c` indicates command execution)

This scheme is unambiguous and provides clear visual cues for each processing type. The `=` operator handles the most common case with minimal syntax, while the `:prefix=` operators use descriptive suffixes (q=quote, v=variable, e=expression, c=command) that make the intent immediately clear. The colon-based syntax is familiar from many configuration systems and provides consistent visual grouping. 