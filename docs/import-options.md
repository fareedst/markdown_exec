# Import Options

This document describes the configuration options that control how `@import` directives work in markdown_exec, including file path resolution, parameter parsing, and text substitution.

## Overview

The `@import` directive allows you to include content from other markdown files with parameter-based text substitution. Import options control:

- **File path resolution**: Where to search for imported files
- **Directive parsing**: How `@import` lines are recognized and parsed
- **Parameter processing**: How parameters are extracted and processed
- **Text substitution**: How parameter values are substituted into imported content

## Options Reference

### `import_paths`

**Environment Variable**: `MDE_IMPORT_PATHS`  
**Type**: String (colon-separated paths)  
**Default**: Empty (uses document directory)

**Description**: Colon-separated list of directory paths to search when resolving imported file names. When an `@import` directive specifies a relative filename, markdown_exec searches these paths in order, then falls back to the current document's directory.

**Usage**:
```bash
# Set via environment variable
export MDE_IMPORT_PATHS="docs/templates:examples/shared:common"

# Or in document opts block
```opts :(document_opts)
import_paths: "docs/templates:examples/shared:common"
```

**Path Resolution Order**:
1. Absolute paths (starting with `/`) are used as-is
2. If `import_paths` is set, search each path in order
3. Finally, search in the current document's directory

**Example**:
```markdown
@import template.md
```

With `import_paths="templates:shared"`, markdown_exec searches:
1. `templates/template.md`
2. `shared/template.md`
3. `./template.md` (current document directory)

---

### `import_directive_line_pattern`

**Environment Variable**: `MDE_IMPORT_PATTERN`  
**Type**: Regular Expression (String)  
**Default**: `^(?<indention> *)@import +(?<name>\S+)(?<params>(?: +\w+(?::(?:[ceqv]|[ceqv]{2})=|=)(?:"[^"]*"|'[^']*'|\S+))*) *\\?$`

**Description**: Regular expression pattern that matches `@import` directive lines. This pattern captures:
- `indention`: Leading whitespace (preserved for indentation)
- `name`: The filename to import
- `params`: Optional space-separated parameters with various value formats
- Optional line continuation marker (`\` at end of line)

**Pattern Components**:
- `^(?<indention> *)` - Captures leading spaces for indentation preservation
- `@import +` - Matches the literal `@import` followed by spaces
- `(?<name>\S+)` - Captures the filename (non-whitespace)
- `(?<params>...)` - Captures optional parameters (see parameter syntax below)
- ` *\\?$` - Optional trailing spaces and line continuation marker

**Parameter Syntax in Pattern**:
- `KEY=value` - Simple assignment
- `KEY:"quoted value"` - Double-quoted value
- `KEY:'quoted value'` - Single-quoted value
- `KEY:ceqv=value` - Parameter type indicators (see parameter symbols below)

**Example Matches**:
```markdown
@import template.md
@import template.md KEY=value
@import template.md KEY="value with spaces" OTHER=123
@import template.md KEY:q="quoted" VAR:v=existing_var \
  CONTINUED:c="command"
```

**Note**: Modifying this pattern requires understanding regex syntax and may break existing imports. Only change if you need custom import directive syntax.

---

### `import_directive_parameter_scan`

**Environment Variable**: `MDE_IMPORT_PATTERN_SCAN`  
**Type**: Regular Expression (String)  
**Default**: `(\w+)(:[ceqv]{1,2}=|=)(?:"([^"]*)"|'([^']*)'|(\S+))`

**Description**: Regular expression pattern that extracts individual parameters from the `params` portion of an `@import` line. This pattern is applied to the captured `params` group from `import_directive_line_pattern`.

**Pattern Components**:
- `(\w+)` - Captures the parameter key (word characters)
- `(:[ceqv]{1,2}=|=)` - Captures the operator (parameter type indicator or simple `=`)
- `(?:"([^"]*)"|'([^']*)'|(\S+))` - Captures the value from:
  - Double-quoted string: `"value"`
  - Single-quoted string: `'value'`
  - Unquoted value: `value`

**Capture Groups**:
1. Parameter key (e.g., `KEY`)
2. Operator (e.g., `=`, `:c=`, `:q=`, `:v=`, `:e=`)
3. Double-quoted value (if used)
4. Single-quoted value (if used)
5. Unquoted value (if used)

**Example**:
For the line: `@import file.md KEY:q="value" VAR:v=existing OTHER=123`

The pattern extracts:
- `KEY`, `:q=`, `"value"` (from group 3)
- `VAR`, `:v=`, `existing` (from group 5)
- `OTHER`, `=`, `123` (from group 5)

**Note**: This pattern works in conjunction with `import_directive_line_pattern`. Only modify if you need custom parameter parsing.

---

### `import_parameter_variable_assignment`

**Environment Variable**: `MDE_IMPORT_PARAMETER_VARIABLE_ASSIGNMENT`  
**Type**: Format String  
**Default**: `"%{key}=%{value}"`

**Description**: Format string used to generate shell variable assignments when parameters require command substitution or expression evaluation. This format is used when a parameter uses `:c=` (command) or `:e=` (expression) operators that need to create shell variables.

**Format Placeholders**:
- `%{key}` - The parameter name
- `%{value}` - The shell code/expression to assign

**Example**:
When processing `KEY:c="ls -la"`, if a new variable needs to be created, the format generates:
```bash
KEY=$(ls -la)
```

**Usage Context**:
This format is used internally when `ParameterExpansion` determines that a parameter requires a new shell variable to be created (e.g., for command substitution results).

**Note**: This is an internal format string. Only modify if you need custom variable assignment syntax in generated shell code.

---

### `import_symbol_command_substitution`

**Environment Variable**: `MDE_IMPORT_SYMBOL_COMMAND_SUBSTITUTION`  
**Type**: String  
**Default**: `:c=`

**Description**: Symbol/operator that indicates a parameter value should be treated as a shell command to execute. The output of the command is used as the substitution value.

**Usage**:
```markdown
@import template.md TIMESTAMP:c="date '+%Y-%m-%d'"
```

This executes `date '+%Y-%m-%d'` and uses its output as the value for `TIMESTAMP` in the imported template.

**Behavior**:
- The command is executed in a shell context
- The command output (stdout) is captured and used as the value
- If the command creates a new variable, `import_parameter_variable_assignment` format is used
- Command output is typically chomped (trailing newline removed)

**Example**:
```markdown
@import report.md GENERATED:c="date '+%Y-%m-%d %H:%M:%S'" LATEST:c="ls -t *.md | head -n 1"
```

**Note**: This symbol is part of the parameter expansion system. See `lib/parameter_expansion.rb` for full details on command substitution behavior.

---

### `import_symbol_evaluated_expression`

**Environment Variable**: `MDE_IMPORT_SYMBOL_EVALUATED_EXPRESSION`  
**Type**: String  
**Default**: `:e=`

**Description**: Symbol/operator that indicates a parameter value should be treated as a shell expression to evaluate. The expression is evaluated with variable expansion, and the result is used as the substitution value.

**Usage**:
```markdown
@import template.md FILENAME:e="report-${COMMON_NAME// /_}-$(date +%Y%m%d).md"
```

This evaluates the shell expression with variable expansion and uses the result for `FILENAME`.

**Behavior**:
- The expression is evaluated in a shell context with variable expansion
- Shell parameter expansion syntax (`${VAR}`, `${VAR:-default}`) is supported
- Command substitution (`$(command)`) within expressions is supported
- The evaluated result is used as the literal substitution value

**Example**:
```markdown
@import template.md \
  DESCRIPTION:e="Classification report for ${COMMON_NAME} (${PLAIN_SPECIES})" \
  YEAR:e="${DISCOVERY_YEAR:-Unknown}"
```

**Note**: This symbol is part of the parameter expansion system. See `lib/parameter_expansion.rb` for full details on expression evaluation behavior.

---

### `import_symbol_raw_literal`

**Environment Variable**: `MDE_IMPORT_SYMBOL_RAW_LITERAL`  
**Type**: String  
**Default**: `=`

**Description**: Symbol/operator that indicates a parameter value should be used as a raw literal string without any processing. This is the default behavior when no type indicator is specified.

**Usage**:
```markdown
@import template.md SPECIES=Pongo FAMILY=Hominidae
```

or explicitly:
```markdown
@import template.md SPECIES:=Pongo FAMILY:=Hominidae
```

**Behavior**:
- The value is used exactly as provided
- No shell evaluation or variable expansion
- No quoting is added automatically
- This is the simplest and most common parameter type

**Example**:
```markdown
@import organism.md \
  COMMON_NAME=Tapanuli \
  SPECIES="Pongo tapanuliensis" \
  GENUS=Pongo \
  YEAR_DISCOVERED=2017
```

**Note**: This is the default behavior. The `=` operator can be omitted in most cases, but explicit `:=` makes the intent clear.

---

### `import_symbol_force_quoted_literal`

**Environment Variable**: `MDE_IMPORT_SYMBOL_FORCE_QUOTED_LITERAL`  
**Type**: String  
**Default**: `:q=`

**Description**: Symbol/operator that indicates a parameter value should be treated as a literal string and automatically wrapped in double quotes during substitution. This ensures the value is treated as a single string even if it contains spaces or special characters.

**Usage**:
```markdown
@import template.md COMMON_NAME:q="Tapanuli Orangutan" SPECIES:q="Pongo tapanuliensis"
```

**Behavior**:
- The value is wrapped in double quotes: `"value"`
- Useful for values with spaces or special characters
- Prevents shell interpretation of the value
- The quotes are added during substitution, not in the parameter itself

**Example**:
```markdown
@import organism.md \
  COMMON_NAME:q="Tapanuli Orangutan" \
  SPECIES:q="Pongo tapanuliensis" \
  DESCRIPTION:q="Endangered primate species"
```

**Comparison**:
- `COMMON_NAME=Tapanuli Orangutan` - May be interpreted as two values
- `COMMON_NAME:q="Tapanuli Orangutan"` - Guaranteed to be one quoted value

**Note**: The value in the `@import` line can be quoted or unquoted; the `:q=` operator ensures the substituted value is always quoted.

---

### `import_symbol_variable_reference`

**Environment Variable**: `MDE_IMPORT_SYMBOL_VARIABLE_REFERENCE`  
**Type**: String  
**Default**: `:v=`

**Description**: Symbol/operator that indicates a parameter value should be treated as a reference to an existing variable from the importing document. The variable's value is looked up and used for substitution.

**Usage**:
```markdown
@import template.md GENUS:v=orangutan_genus FAMILY:v=hominidae_family
```

This looks up the values of `orangutan_genus` and `hominidae_family` from the current document's variables and uses them for substitution.

**Behavior**:
- The parameter value is treated as a variable name
- The variable is looked up in the current document's context
- If the variable exists, its value is used
- If the variable doesn't exist, the substitution may fail or use an empty value
- Variable references use shell syntax: `${VAR_NAME}`

**Example**:
```markdown
# In the importing document
```vars
orangutan_genus: Pongo
discovery_year_2017: 2017
```

@import organism.md \
  GENUS:v=orangutan_genus \
  YEAR_DISCOVERED:v=discovery_year_2017
```

**Note**: Variable references are resolved from the importing document's variable context, not from shell environment variables.

---

## Parameter Type Summary

The import system supports five parameter processing types:

| Symbol | Operator | Type | Description |
|--------|----------|------|-------------|
| `=` | `=` | Raw Literal | Direct text replacement (default) |
| `:q=` | `:q=` | Force-Quoted Literal | Literal value wrapped in quotes |
| `:v=` | `:v=` | Variable Reference | Reference to existing variable |
| `:e=` | `:e=` | Evaluated Expression | Shell expression with variable expansion |
| `:c=` | `:c=` | Command Substitution | Execute command and use output |

## Examples

### Basic Import
```markdown
@import shared/header.md
```

### Import with Simple Parameters
```markdown
@import template.md TITLE="My Document" AUTHOR=John YEAR=2024
```

### Import with Parameter Types
```markdown
@import organism.md \
  COMMON_NAME:q="Tapanuli Orangutan" \
  SPECIES:q="Pongo tapanuliensis" \
  GENUS:v=orangutan_genus \
  YEAR_DISCOVERED:v=discovery_year \
  TIMESTAMP:c="date '+%Y-%m-%d %H:%M:%S'" \
  FILENAME:e="report-${COMMON_NAME// /_}.md"
```

### Import with Line Continuation
```markdown
@import template.md \
  PARAM1=value1 \
  PARAM2=value2 \
  PARAM3=value3
```

## Related Options

- `menu_include_imported_blocks` - Control whether imported blocks appear in menus
- `menu_include_imported_notes` - Control whether imported notes appear in menus
- `menu_import_level_match` - Filter imported blocks by import level

## Implementation Details

The import system is implemented in:
- `lib/cached_nested_file_reader.rb` - Main import processing
- `lib/parameter_expansion.rb` - Parameter expansion logic
- `lib/find_files.rb` - File path resolution

For more details on parameter expansion, see the comprehensive documentation in `lib/parameter_expansion.rb`.

## Related Documentation

- [Block Naming Patterns](block-naming-patterns.md) - How imported blocks are named
- [Block Filtering](block-filtering.md) - Filtering imported blocks
- [CLI Reference](cli-reference.md) - Command-line usage

## Additional Resources

- [Import Substitution README](../IMPORT_SUBSTITUTION_README.md)
- [Examples: Import with Substitution](../examples/import_with_substitution_demo.md)
- [Parameter Expansion Documentation](../lib/parameter_expansion.rb)

