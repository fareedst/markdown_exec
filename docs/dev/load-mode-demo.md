# LOAD Block Mode Demonstration

This document demonstrates the difference between `mode: append` (default) and `mode: replace` for LOAD blocks.

## Setup: Create Initial Inherited Lines

First, let's establish some inherited lines that will be used to test the different modes:

```vars :setup_environment
PROJECT_NAME: load-mode-demo
VERSION: 1.0.0
AUTHOR: MDE Testing
```

```bash :create_initial_context
echo "# Initial Context"
echo "PROJECT: $PROJECT_NAME"
echo "VERSION: $VERSION" 
echo "AUTHOR: $AUTHOR"
echo ""
echo "# These lines are inherited and available for LOAD operations"
```

## Test Files Setup

Create test files in document_configurations directory for loading:

```bash :create_test_files
mkdir -p document_configurations/load_demo

# Create append-demo.sh
cat > document_configurations/load_demo/append-demo.sh << 'EOF'
echo "=== Loaded via APPEND mode ==="
echo "This content will be ADDED to existing inherited lines"
echo "Original context should still be visible above"
echo "Loaded at: $(date)"
EOF

# Create replace-demo.sh  
cat > document_configurations/load_demo/replace-demo.sh << 'EOF'
echo "=== Loaded via REPLACE mode ==="
echo "This content REPLACES all inherited lines"
echo "Original context should NOT be visible"
echo "Loaded at: $(date)"
echo "Only this loaded content should execute"
EOF

echo "Test files created successfully"
ls -la document_configurations/load_demo/
```

## Test 1: Default Mode (Append)

This LOAD block uses the default behavior where loaded content is **appended** to inherited lines:

```load :test_append_mode
directory: document_configurations/load_demo
filename_pattern: '^(?<name>.*)$'
glob: 'append-demo.sh'
view: '%{name}'
```

Expected behavior:
- The initial context (PROJECT, VERSION, AUTHOR) should execute first
- Then the loaded content from append-demo.sh should execute
- Both sets of lines are combined

## Test 2: Explicit Append Mode

This LOAD block explicitly specifies `mode: append` (same as default):

```load :test_explicit_append
directory: document_configurations/load_demo  
filename_pattern: '^(?<name>.*)$'
glob: 'append-demo.sh'
view: '%{name}'
mode: append
```

Expected behavior: Same as Test 1 - inherited lines + loaded content

## Test 3: Replace Mode

This LOAD block uses `mode: replace` where loaded content **replaces** all inherited lines:

```load :test_replace_mode
directory: document_configurations/load_demo
filename_pattern: '^(?<name>.*)$' 
glob: 'replace-demo.sh'
view: '%{name}'
mode: replace
```

Expected behavior:
- The initial context (PROJECT, VERSION, AUTHOR) should NOT execute
- Only the loaded content from replace-demo.sh should execute
- Inherited lines are completely replaced

## Test 4: Multiple Loads with Different Modes

First, load with append to build up context:

```load :build_context_append
directory: document_configurations/load_demo
filename_pattern: '^(?<name>.*)$'
glob: 'append-demo.sh' 
view: '%{name}'
mode: append
```

Then load with replace to demonstrate clearing:

```load :clear_and_replace
directory: document_configurations/load_demo
filename_pattern: '^(?<name>.*)$'
glob: 'replace-demo.sh'
view: '%{name}'
mode: replace  
```

Expected behavior:
- After first load: initial context + append-demo content
- After second load: only replace-demo content (everything else cleared)

## Verification Commands

Check what's in our inherited lines at different points:

```bash :check_inherited_state
echo "=== Current Inherited State ==="
echo "If you see initial setup variables, APPEND mode is working"
echo "If you only see loaded content, REPLACE mode is working"
echo ""
env | grep -E "(PROJECT_NAME|VERSION|AUTHOR)" || echo "No setup variables found - likely REPLACE mode was used"
```

## Use Cases for Each Mode

### Mode: Append (Default)
- **Use case**: Adding functionality to existing context
- **Example**: Loading utility functions while keeping current environment
- **Behavior**: Inherited lines + loaded content

### Mode: Replace  
- **Use case**: Starting fresh with completely new context
- **Example**: Loading a different configuration that should not mix with current state
- **Behavior**: Only loaded content, inherited lines discarded

## Clean Up

```bash :cleanup
rm -rf document_configurations/load_demo
echo "Test files cleaned up"
```

## Implementation Notes

The `mode` parameter in LOAD blocks controls how the loaded content interacts with inherited lines:

- `mode: append` (default): `inherited_lines + loaded_content`  
- `mode: replace`: `loaded_content` (inherited_lines ignored)

This is implemented in the `next_state_append_code` method which now accepts a mode parameter and conditionally includes inherited lines based on the mode value. 