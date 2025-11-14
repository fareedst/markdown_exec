# Getting Started with MarkdownExec

A quick guide to get you up and running with MarkdownExec.

## Installation

```bash
gem install markdown_exec
```

## Quick Start

### Interactive Mode (Recommended)

The simplest way to use MarkdownExec is in interactive mode:

```bash
# Process README.md in current directory
mde

# Process a specific markdown file
mde my-document.md

# Select from markdown files in current folder
mde .
```

### Command Line Mode

Execute specific blocks directly without the interactive menu:

```bash
# Execute a specific block
mde my-document.md my-block-name

# Or use the flag
mde my-document.md --block-name my-block-name
```

## Basic Concepts

### Named Code Blocks

Create executable code blocks with names:

```bash :setup
echo "Setting up environment"
```

The block name (`setup`) is extracted from the fenced code block start line.

### Block Dependencies

Blocks can require other blocks to run first:

```bash :deploy +setup +test
echo "Deploying after setup and test"
```

The `+setup` and `+test` indicate that those blocks must execute first.

### Interactive Forms (UX Blocks)

Create interactive forms for user input:

```ux
name: USER_NAME
prompt: Enter your name
init: Guest
```

### Cross-Document Navigation

Navigate between documents while maintaining context:

```link
file: next-document.md
vars:
  current_user: ${USER_NAME}
```

## Common Usage Patterns

### Quick Execution

```bash
# Execute a specific block directly
mde README.md deploy

# With approval (review script before execution)
mde README.md deploy --user-must-approve 1
```

### Interactive Development

```bash
# Open document in interactive mode
mde README.md

# Search and open a document
mde --open "setup"
```

### Discovery

```bash
# List available documents
mde --list-docs

# List blocks in a document
mde README.md --list-blocks

# Search for content
mde --find "database"
```

### Script Management

```bash
# Save scripts and output
mde README.md -b deploy --save-executed-script 1 --save-execution-output 1
```

## Configuration

### Environment Variables

Set options via environment variables:

```bash
export MDE_USER_MUST_APPROVE=1
export MDE_SAVE_EXECUTED_SCRIPT=1
mde README.md deploy
```

### Configuration Files

Create a `.mde.yml` file in your project:

```yaml
# .mde.yml
save_executed_script: true
user_must_approve: true
output_script: true
```

## Next Steps

- [CLI Reference](cli-reference.md) - Complete command-line reference
- [Execution Control](execution-control.md) - Control how scripts execute
- [Block Execution Modes](block-execution-modes.md) - Configure execution modes
- [Block Filtering](block-filtering.md) - Filter and select blocks
- [UX Blocks](ux-blocks.md) - Interactive form system
- [Import Options](import-options.md) - Template system with @import
- [Tab Completion](tab-completion.md) - Set up tab completion

## Example Workflow

Here's a complete example demonstrating key features:

### Step 1: User Input

```ux :user-setup
name: USER_NAME
prompt: Enter your name
init: Guest
```

```ux :environment
name: ENVIRONMENT
allow:
  - development
  - staging
  - production
prompt: Select environment
```

### Step 2: Automated Setup

```bash :setup +user-setup +environment
echo "Setting up for user: ${USER_NAME}"
echo "Environment: ${ENVIRONMENT}"
```

### Step 3: Conditional Logic

```bash :deploy +setup
if [ "${ENVIRONMENT}" = "production" ]; then
  echo "Deploying to production with extra safety checks"
else
  echo "Deploying to ${ENVIRONMENT}"
fi
```

### Step 4: Cross-Document Navigation

```link
file: next-workflow.md
vars:
  user: ${USER_NAME}
  env: ${ENVIRONMENT}
```

## Getting Help

- Run `mde --help` for command-line help
- See [CLI Reference](cli-reference.md) for detailed option documentation
- Check the [README](../README.md) for feature overview

