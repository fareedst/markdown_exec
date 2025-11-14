# UX Blocks

UX blocks create interactive forms that prompt users for input, validate values, and initialize from various sources. This document covers the complete UX block system.

## Overview

UX blocks provide an interactive form system for markdown_exec that allows you to:
- Prompt users for input with custom prompts
- Validate input using regex patterns
- Transform validated input using format strings
- Initialize values from environment variables, commands, or allowed lists
- Create dynamic selection menus from command output
- Chain UX blocks with dependencies

## Block Structure

A UX block is a fenced code block with type `ux`:

```ux
name: VARIABLE_NAME
prompt: Enter a value
init: Default value
```

## Key Fields

### Required Fields

- **`name`**: The variable name that will be set (required)

### Optional Fields

- **`prompt`**: Text displayed when prompting for input
- **`init`**: Initial value or initialization method (see Init Phase below)
- **`act`**: Activation method (see Act Phase below)
- **`allow`**: List of allowed values for selection
- **`validate`**: Regex pattern for input validation
- **`transform`**: Format string for transforming validated input
- **`format`**: Format string for displaying the value
- **`echo`**: Shell expression to evaluate
- **`exec`**: Command to execute
- **`require`**: List of other UX block names that must be set first

## Init and Act Behavior

The `init` and `act` keys determine which other key is read for processing during initialization (when document is loaded) and activation (when block is selected) respectively.

### Init Phase

The init phase runs when the document is loaded. The behavior depends on the `init` value:

1. **`init: false`**: No initialization occurs
2. **`init: "string"`**: That string becomes the initial value
3. **`init: :allow`**: First value from `allow` list is used
4. **`init: :echo`**: Value from `echo` key is evaluated and returned
5. **`init: :exec`**: Command from `exec` key is executed and stdout is returned
6. **`init` not present**: Defaults to first available in order:
   - `:allow` if `allow` exists
   - `:default` if `default` exists
   - `:echo` if `echo` exists
   - `:exec` if `exec` exists
   - `false` if none of the above exist

### Act Phase

The act phase runs when the block is activated (selected). The behavior depends on the `act` value:

1. **`act: false`**: Block cannot be activated
2. **`act: :allow`**: User selects from `allow` list
3. **`act: :echo`**: Value from `echo` key is evaluated and returned
4. **`act: :edit`**: User is prompted for input
5. **`act: :exec`**: Command from `exec` key is executed and stdout is returned
6. **`act` not present**: Defaults to:
   - If `init` is `false`: First available in order: `:allow`, `:echo`, `:edit`, `:exec`
   - Otherwise:
     - `:allow` if `allow` exists
     - `:edit` if `allow` does not exist

## Examples

### Simple Variable Display and Edit

```ux
init: Guest
name: USER_NAME
prompt: Enter your name
```

- On init: Sets `USER_NAME` to "Guest"
- On act: Prompts user to enter their name

### Command Output Initialization

```ux
name: CURRENT_DIR
init: :exec
exec: basename $(pwd)
transform: :chomp
```

- On init: Executes `basename $(pwd)` and uses output as value
- On act: Prompts for input (default behavior)

### Echo-based Initialization

```ux
name: SHELL_VERSION
init: :echo
echo: $SHELL
```

- On init: Evaluates `$SHELL` and uses result as value
- On act: Evaluates echo string (default behavior)

### Selection from Allowed Values

```ux
name: ENVIRONMENT
allow:
  - development
  - staging
  - production
prompt: Select environment
```

- On init: Uses first allowed value (development)
- On act: Shows menu of allowed values for selection

### Email Validation

```ux
name: USER_EMAIL
prompt: Enter email address
validate: '(?<local>[^@]+)@(?<domain>[^@]+)'
transform: '%{local}@%{domain}'
```

- Validates input matches email pattern
- Transforms using captured groups from validation regex

### Version Number Validation

```ux
name: VERSION
prompt: Enter version number
validate: '(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)'
transform: '%{major}.%{minor}.%{patch}'
```

- Validates version number format
- Normalizes format using captured groups

### Git Branch Selection with Validation

```ux
name: BRANCH_NAME
init: ":exec"
exec: "git branch --format='%(refname:short)'"
validate: '^(?<type>feature|bugfix|hotfix)/(?<ticket>[A-Z]+-\d+)-(?<desc>.+)$'
transform: "${type}/${ticket}-${desc}"
prompt: "Select or enter branch name"
```

- On init: Executes git command to get branch list
- Validates branch name format
- Transforms to normalized format

### Environment Configuration with Dependencies

```ux
name: DATABASE_URL
require:
  - ENVIRONMENT
  - DB_HOST
  - DB_PORT
format: "postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
```

- Requires other UX blocks to be set first
- Formats final value using required variables

### Multi-step Configuration

```ux
name: DEPLOY_CONFIG
require:
  - ENVIRONMENT
  - VERSION
init: ":echo"
echo: "Deploying ${VERSION} to ${ENVIRONMENT}"
act: ":exec"
exec: "deploy.sh ${ENVIRONMENT} ${VERSION}"
```

- On init: Evaluates echo string with dependencies
- On act: Executes deploy script with parameters

### Conditional Initialization

```ux
name: API_KEY
init: ":allow"
allow:
  - ${PROD_API_KEY}
  - ${STAGING_API_KEY}
  - ${DEV_API_KEY}
require:
  - ENVIRONMENT
```

- On init: Uses first allowed API key
- On act: Shows menu of allowed API keys for selection
- Requires ENVIRONMENT to be set first

### Formatted Output with Validation

```ux
name: PHONE_NUMBER
prompt: "Enter phone number"
validate: '(?<country>\d{1,3})(?<area>\d{3})(?<number>\d{7})'
transform: "+${country} (${area}) ${number}"
format: "Phone: ${PHONE_NUMBER}"
```

- Validates phone number format
- Transforms to formatted display
- Uses format string for final display

### Command Output with Transformation

```ux
name: GIT_STATUS
init: ":exec"
exec: "git status --porcelain"
validate: '(?<status>[AMDR])\s+(?<file>.+)'
transform: "${status}: ${file}"
format: "Changes: ${GIT_STATUS}"
```

- On init: Executes git status command
- Validates and transforms output
- Formats for display

## Advanced Patterns

### Echo on Init, Exec on Act

```ux
name: DEPLOY_CONFIG
init: :echo
echo: "Deploying ${VERSION} to ${ENVIRONMENT}"
act: :exec
exec: "deploy.sh ${ENVIRONMENT} ${VERSION}"
```

**Behavior:**
- On init: Evaluates echo string "Deploying ${VERSION} to ${ENVIRONMENT}"
- On act: Executes deploy.sh with environment and version parameters

### Allow on Init, Edit on Act

```ux
name: ENVIRONMENT
init: :allow
allow:
  - development
  - staging
  - production
act: :edit
prompt: Select environment
```

**Behavior:**
- On init: Uses first allowed value (development)
- On act: Prompts user to select from allowed values

### Exec on Init, Echo on Act

```ux
name: CURRENT_DIR
init: :exec
exec: basename $(pwd)
act: :echo
echo: "Current directory: ${CURRENT_DIR}"
```

**Behavior:**
- On init: Executes basename command on current directory
- On act: Evaluates echo string with current directory value

### Allow on Both

```ux
name: API_KEY
init: :allow
allow:
  - ${PROD_API_KEY}
  - ${STAGING_API_KEY}
  - ${DEV_API_KEY}
act: :allow
require:
  - ENVIRONMENT
```

**Behavior:**
- On init: Uses first allowed API key
- On act: Shows menu of allowed API keys for selection

### Echo on Both

```ux
name: SHELL_VERSION
init: :echo
echo: $SHELL
act: :echo
echo: "Using shell: ${SHELL_VERSION}"
```

**Behavior:**
- On init: Gets shell value from environment
- On act: Evaluates echo string with current shell value

## Validation and Transformation

### Validation Regex

The `validate` field uses Ruby regex syntax with named capture groups:

```ux
validate: '(?<local>[^@]+)@(?<domain>[^@]+)'
```

This creates capture groups that can be referenced in the `transform` field.

### Transformation Format

The `transform` field uses format string syntax with capture group references:

```ux
transform: '%{local}@%{domain}'
```

Or with shell variable expansion:

```ux
transform: "${local}@${domain}"
```

### Format Display

The `format` field controls how the value is displayed in menus:

```ux
format: "Phone: ${PHONE_NUMBER}"
```

## Dependencies

UX blocks can depend on other UX blocks using the `require` field:

```ux
name: DATABASE_URL
require:
  - ENVIRONMENT
  - DB_HOST
  - DB_PORT
```

When a UX block has dependencies, those blocks must be initialized or activated first before this block can be used.

## Related Documentation

- [Block Naming Patterns](block-naming-patterns.md) - How block names are parsed
- [Block Execution Modes](block-execution-modes.md) - Execution mode configuration
- [Import Options](import-options.md) - Using UX blocks with imports

