# Block Filtering Options

This document explains how blocks are filtered for inclusion or exclusion from menus and execution in markdown_exec.

## Overview

Markdown Exec provides multiple mechanisms to filter blocks:

1. **Type-based filtering**: Filter by block type (bash, expect, etc.)
2. **Name-based filtering**: Filter by block name using regex patterns
3. **Shell-based filtering**: Filter by shell type using regex patterns
4. **Pattern-based filtering**: Use naming patterns (hidden, include, wrapper)

These filters work together in a specific order to determine which blocks appear in menus and can be executed.

## Configuration Options

### Bash Only

- **Option**: `bash_only`
- **Environment Variable**: `MDE_BASH_ONLY`
- **Default**: `false`
- **Description**: Execute only blocks of type "bash"

When enabled, only blocks explicitly marked as type "bash" will be included. Blocks without a shell type specified will be excluded.

**Usage:**
```opts
bash_only: true
```

### Exclude by Name Regex

- **Option**: `exclude_by_name_regex`
- **Environment Variable**: `MDE_EXCLUDE_BY_NAME_REGEX`
- **Default**: (empty)
- **Description**: Regex pattern to exclude blocks whose names match

Blocks whose names match this regex pattern will be excluded from menus and execution. This is checked after name selection filters.

**Example:**
```opts
exclude_by_name_regex: '^test-|^internal-'
```

This excludes blocks whose names start with `test-` or `internal-`.

### Exclude by Shell Regex

- **Option**: `exclude_by_shell_regex`
- **Environment Variable**: `MDE_EXCLUDE_BY_SHELL_REGEX`
- **Default**: (empty)
- **Description**: Regex pattern to exclude blocks whose shell type matches

Blocks whose shell type matches this regex pattern will be excluded from menus and execution.

**Example:**
```opts
exclude_by_shell_regex: '^(python|ruby)$'
```

This excludes blocks with shell types "python" or "ruby".

### Exclude Expect Blocks

- **Option**: `exclude_expect_blocks`
- **Environment Variable**: `MDE_EXCLUDE_EXPECT_BLOCKS`
- **Default**: `true`
- **Description**: Whether to exclude all blocks of type "expect" from menus

When enabled (default), all blocks of type "expect" are automatically excluded from menus. Expect blocks are typically used for automated testing and are not meant for interactive execution.

**Usage:**
```opts
exclude_expect_blocks: false  # Show expect blocks in menu
```

### Hide Blocks by Name

- **Option**: `hide_blocks_by_name`
- **Environment Variable**: `MDE_HIDE_BLOCKS_BY_NAME`
- **Default**: `true`
- **Description**: Whether to hide blocks whose names match block_name_hide_custom_match pattern

When enabled, blocks whose names match the `block_name_hide_custom_match` pattern (default: `^-.+-$`) will be hidden from menus. This works in conjunction with the naming pattern options.

**Usage:**
```opts
hide_blocks_by_name: true
block_name_hide_custom_match: '^internal-.*'
```

### Select by Name Regex

- **Option**: `select_by_name_regex`
- **Environment Variable**: `MDE_SELECT_BY_NAME_REGEX`
- **Default**: (empty)
- **Description**: Regex pattern to include only blocks whose names match

When specified, only blocks whose names match this regex pattern will be included. All other blocks will be excluded. This is checked before exclude filters.

**Example:**
```opts
select_by_name_regex: '^production-'
```

This includes only blocks whose names start with `production-`.

### Select by Shell Regex

- **Option**: `select_by_shell_regex`
- **Environment Variable**: `MDE_SELECT_BY_SHELL_REGEX`
- **Default**: (empty)
- **Description**: Regex pattern to include only blocks whose shell type matches

When specified, only blocks whose shell type matches this regex pattern will be included. All other blocks will be excluded.

**Example:**
```opts
select_by_shell_regex: '^(bash|sh)$'
```

This includes only blocks with shell types "bash" or "sh".

## How It Works

The filtering system in `lib/filter.rb` evaluates blocks in a specific order:

### Filter Evaluation Order

1. **Depth Check**: Blocks with `depth == true` are excluded
2. **Chrome Check**: Decorative blocks (chrome) are included unless `no_chrome` is enabled
3. **Expect Blocks**: If `exclude_expect_blocks` is true, expect blocks are excluded
4. **Hidden Name Check**: If `hide_blocks_by_name` is enabled and name matches `block_name_hide_custom_match`, block is excluded
5. **Include Name Check**: If name matches `block_name_hidden_match`, block is included
6. **Wrapper Name Check**: If name matches `block_name_wrapper_match`, block is included
7. **Exclude Filters**: 
   - If `name_exclude` is true (name matches `exclude_by_name_regex`) → exclude
   - If `shell_exclude` is true (shell matches `exclude_by_shell_regex`) → exclude
8. **Select Filters**:
   - If `name_select` is false (name doesn't match `select_by_name_regex`) → exclude
   - If `shell_select` is false (shell doesn't match `select_by_shell_regex`) → exclude
9. **Select Filters (positive)**:
   - If `name_select` is true → include
   - If `shell_select` is true → include
10. **Default Filters**:
    - If `name_default` is false or `shell_default` is false → exclude
11. **Default**: Include the block

### Filter Logic Details

**Name Filters** (`apply_name_filters`):
- `select_by_name_regex` is checked first - if specified, only matching blocks pass
- `exclude_by_name_regex` is checked second - matching blocks are excluded
- If neither is specified, all blocks pass name filtering

**Shell Filters** (`apply_shell_filters`):
- If `bash_only` is true and shell is empty, block is excluded
- `select_by_shell_regex` is checked first - if specified, only matching blocks pass
- `exclude_by_shell_regex` is checked second - matching blocks are excluded
- Expect blocks are marked for exclusion if `exclude_expect_blocks` is true

**Other Filters** (`apply_other_filters`):
- Disabled blocks (via `block_disable_match`) are marked
- Hidden name patterns are checked if `hide_blocks_by_name` is enabled
- Include and wrapper name patterns are checked

## Usage Examples

### Filter to Only Bash Blocks

```opts
bash_only: true
```

Only blocks explicitly marked as `bash` will be included.

### Exclude Test Blocks

```opts
exclude_by_name_regex: '^test'
```

All blocks whose names start with "test" will be excluded.

### Include Only Production Blocks

```opts
select_by_name_regex: '^production-'
```

Only blocks whose names start with "production-" will be included.

### Filter by Shell Type

```opts
select_by_shell_regex: '^(bash|sh)$'
exclude_by_shell_regex: 'python'
```

Include only bash/sh blocks, but exclude any Python blocks.

### Hide Internal Blocks

```opts
hide_blocks_by_name: true
block_name_hide_custom_match: '^-internal-'
```

Blocks with names like `-internal-setup-` will be hidden.

### Combined Filtering

```opts
# Only show bash blocks
bash_only: true

# But exclude test blocks
exclude_by_name_regex: '^test'

# And only include production blocks
select_by_name_regex: '^production-'
```

This configuration will:
1. Only include bash blocks
2. Exclude blocks starting with "test"
3. Only include blocks starting with "production-"

## Filter Priority

When multiple filters conflict, the evaluation order determines priority:

1. **Explicit excludes** (exclude_by_name_regex, exclude_by_shell_regex) take precedence
2. **Select filters** (select_by_name_regex, select_by_shell_regex) act as allowlists
3. **Pattern-based filters** (hidden, include, wrapper) are evaluated early
4. **Type-based filters** (bash_only, exclude_expect_blocks) are evaluated early

## Related Configuration

- **Block Naming Patterns**: `block_name_hide_custom_match`, `block_name_hidden_match`, `block_name_wrapper_match` - work with `hide_blocks_by_name`
- **Block Execution Modes**: `block_disable_match` - marks blocks as disabled
- **Menu Options**: `menu_include_imported_blocks` - controls imported block visibility

## Related Documentation

- [Block Naming Patterns](block-naming-patterns.md) - Pattern-based filtering
- [Block Execution Modes](block-execution-modes.md) - Execution mode filtering
- [Block Scanning Patterns](block-scanning-patterns.md) - How block content is scanned
- [Import Options](import-options.md) - Imported block filtering
- [CLI Reference](cli-reference.md) - Command-line usage

