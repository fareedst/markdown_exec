# MarkdownExec

[![MarkdownExec For Interactive Bash Instruction](https://raw.githubusercontent.com/fareedst/markdown_exec/main/demo/trap.demo1.gif)](https://raw.githubusercontent.com/fareedst/markdown_exec/main/demo/trap.demo1.mp4)

*Click the GIF above to view the full video with audio (MP4)*

Transform static markdown into interactive, executable workflows. Build complex scripts with named blocks, interactive forms, cross-document navigation, and template systems.

## Key Features

### Interactive Code Execution
- **Named Blocks**: Create reusable code blocks with dependencies
- **Block Requirements**: Automatically include required blocks in execution order
- **Interactive Selection**: Choose blocks from intuitive menus
- **Script Approval**: Review generated scripts before execution

### UX Blocks - Interactive Forms
- **Variable Input**: Create interactive forms for user input
- **Validation**: Built-in regex validation with custom transforms
- **Dynamic Menus**: Selection from allowed values or command output
- **Auto-initialization**: Set values from environment, commands, or defaults
- **Dependencies**: Chain UX blocks with complex relationships

### Cross-Document Navigation
- **Link Blocks**: Navigate between markdown files seamlessly
- **Variable Passing**: Share data between documents
- **Inherited Context**: Maintain state across document boundaries
- **HyperCard-style Navigation**: Create interactive document stacks

### Template System & Imports
- **Import Directives**: Include content from other files with `@import`
- **Parameter Substitution**: Replace variables in imported content
- **Shell Expansions**: Use `${variable}` and `$(command)` syntax throughout documents
- **Dynamic Content**: Generate content based on user selections

### Advanced Block Types
- **Shell Blocks**: Execute bash shells
- **UX Blocks**: Interactive forms with validation, transforms, and dynamic behavior
- **Vars Blocks**: Define variables in YAML format
- **Opts Blocks**: Configure document behavior and appearance
- **Link Blocks**: Cross-document navigation and variable passing

### State Management
- **Script Persistence**: Save and replay executed scripts
- **Output Logging**: Capture and review execution results
- **State Inheritance**: Manage context across sessions
- **Configuration**: Flexible options via environment, files, or CLI

## Installation

```bash
gem install markdown_exec
```

## Quick Start

### Interactive Mode (Recommended)
```bash
mde                    # Process README.md in current folder
mde my-document.md     # Process specific markdown file
mde .                  # Select from markdown files in current folder
```

### Command Line Mode
```bash
mde my-document.md my-block    # Execute specific block directly
mde --list-blocks              # List all available blocks
mde --list-docs                # List all markdown documents
```

## Interactive Features

### UX Blocks - Interactive Forms

Create interactive forms that prompt users for input:

<pre><code>```ux
name: USER_NAME
prompt: Enter your name
init: Guest
```
</code></pre>

<pre><code>```ux
name: ENVIRONMENT
allow:
  - development
  - staging
  - production
prompt: Select environment
```
</code></pre>

<pre><code>```ux
name: EMAIL
prompt: Enter email address
validate: '(?<local>[^@]+)@(?<domain>[^@]+)'
transform: '%{local}@%{domain}'
```
</code></pre>

### Cross-Document Navigation

Navigate between documents while maintaining context:

<pre><code>```link
file: next-document.md
vars:
  current_user: ${USER_NAME}
  environment: ${ENVIRONMENT}
```
</code></pre>

### Template System

Use imports with parameter substitution:

```
@import template.md USER_NAME=John ENVIRONMENT=production
```
</code></pre>

### Block Dependencies

Create complex workflows with automatic dependency resolution:

<pre><code>```bash :deploy +setup +test +deploy
echo "Deploying to ${ENVIRONMENT}"
```
</code></pre>

<pre><code>```bash :setup
echo "Setting up environment"
```
</code></pre>

<pre><code>```bash :test
echo "Running tests"
```
</code></pre>

## Advanced Usage

### Configuration

```
# Environment variables
export MDE_SAVE_EXECUTED_SCRIPT=1
export MDE_USER_MUST_APPROVE=1

# Configuration file (.mde.yml)
save_executed_script: true
user_must_approve: true

# Command line
mde --save-executed-script 1 --user-must-approve 1
```

### Script Management

```bash
mde --save-executed-script 1      # Save executed scripts
mde --list-recent-scripts         # List saved scripts
mde --select-recent-script        # Execute saved script
mde --save-execution-output 1     # Save execution output
```

## Block Types Reference

### Shell Blocks
<pre><code>```bash
echo "Hello World"
```
</code></pre>

### UX Blocks (Interactive Forms)
<pre><code>```ux
name: USER_NAME
prompt: Enter your name
init: Guest
```
</code></pre>

<pre><code>```ux
name: ENVIRONMENT
allow:
  - development
  - staging
  - production
act: :allow
```
</code></pre>

<pre><code>```ux
name: CURRENT_DIR
exec: basename $(pwd)
transform: :chomp
```
</code></pre>

<pre><code>```ux
name: EMAIL
prompt: Enter email address
validate: '(?<local>[^@]+)@(?<domain>[^@]+)'
transform: '%{local}@%{domain}'
```
</code></pre>

### Variable Blocks
<pre><code>```vars
DATABASE_URL: postgresql://localhost:5432/myapp
DEBUG: true
```
</code></pre>

### Link Blocks (Cross-Document Navigation)
<pre><code>```link
file: next-page.md
vars:
  current_user: ${USER_NAME}
```
</code></pre>

### Data Blocks (YAML)
<pre><code>```yaml
users:
  - name: John
    role: admin
  - name: Jane
    role: user
```
</code></pre>

### Import Directives
```
@import template.md USER_NAME=John ENVIRONMENT=production
```

### Options Blocks
<pre><code>```opts :(document_opts)
user_must_approve: true
save_executed_script: true
menu_ux_row_format: 'DEFAULT %{name} = ${%{name}}'
```
</code></pre>

## Configuration

### Environment Variables
<pre><code>```bash
export MDE_SAVE_EXECUTED_SCRIPT=1
export MDE_USER_MUST_APPROVE=1
```
</code></pre>

### Configuration Files
<pre><code>```yaml
# .mde.yml
save_executed_script: true
user_must_approve: true
menu_with_inherited_lines: true
```
</code></pre>

### Command Line Options
```bash
mde --save-executed-script 1 --user-must-approve 1 --config my-config.yml
```

## Tab Completion

See [Tab Completion Documentation](docs/tab-completion.md) for installation and usage instructions.

## Example: Interactive Workflow

This example demonstrates a complete interactive workflow with UX blocks, dependencies, and cross-document navigation:

### Step 1: User Input
<pre><code>```ux :user-setup
name: USER_NAME
prompt: Enter your name
init: Guest
```
</code></pre>

<pre><code>```ux :environment
name: ENVIRONMENT
allow:
  - development
  - staging
  - production
prompt: Select environment
```
</code></pre>

### Step 2: Automated Setup
Prompts the user for both values and generates output.
<pre><code>```bash :setup +user-setup +environment
echo "Setting up for user: ${USER_NAME}"
echo "Environment: ${ENVIRONMENT}"
```
</code></pre>

### Step 3: Conditional Logic
<pre><code>```bash :deploy +setup
if [ "${ENVIRONMENT}" = "production" ]; then
  echo "Deploying to production with extra safety checks"
else
  echo "Deploying to ${ENVIRONMENT}"
fi
```
</code></pre>

### Step 4: Cross-Document Navigation
<pre><code>```link
file: next-workflow.md
vars:
  user: ${USER_NAME}
  env: ${ENVIRONMENT}
```
</code></pre>

# Testing

## Docker Testing Environment

For a complete testing environment with all dependencies, use the Docker testing container:

```bash
# Build the test environment
docker build -f Dockerfile.test -t markdown-exec-test .

# Run all tests (RSpec, Minitest, and BATS)
docker run -it markdown-exec-test bash -c 'bundle exec rake test'

# Run individual test suites
docker run -it markdown-exec-test bash -c 'bundle exec rspec'          # RSpec only
docker run -it markdown-exec-test bash -c 'bundle exec rake minitest'  # Minitest only
docker run -it markdown-exec-test bash -c 'bundle exec rake bats'      # BATS tests only

# Enter the container interactively
docker run --rm -it markdown-exec-test bash
```

## Local Testing

Execute tests for individual libraries locally:

`bundle exec rake minitest`

# License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

# Code of Conduct

Everyone interacting in the MarkdownExec project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/fareedst/markdown_exec/blob/master/CODE_OF_CONDUCT.md).
