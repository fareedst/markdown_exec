# Semantic Tokens

**STDD Methodology Version**: 1.0.0

## Overview
This document defines semantic tokens (keywords, identifiers, and concepts) that tie together all documentation, code, and tests. These tokens provide a consistent vocabulary for discussing the system.

## Token Format

```
[TYPE:IDENTIFIER]
```

## Token Types

- `[REQ:*]` - Requirements (functional/non-functional) - **The source of intent**
- `[ARCH:*]` - Architecture decisions - **High-level design choices that preserve intent**
- `[IMPL:*]` - Implementation decisions - **Low-level choices that preserve intent**
- `[TEST:*]` - Test specifications - **Validation of intent**

## Token Naming Convention

- Use UPPER_SNAKE_CASE for identifiers
- Be descriptive but concise
- Example: `[REQ:DUPLICATE_PREVENTION]` not `[REQ:DP]`

## Cross-Reference Format

When referencing other tokens:

```markdown
[IMPL:EXAMPLE] Description [ARCH:DESIGN] [REQ:REQUIREMENT]
```

## Requirements Tokens

### Core Functionality
- `[REQ:SHEBANG_HIDING]` - CLI option to hide shebang lines in document output (default enabled)
- `[REQ:EXAMPLE_FEATURE]` - Example feature requirement
- Add your requirements tokens here

### Non-Functional Requirements
- `[REQ:PERFORMANCE]` - Performance requirements
- `[REQ:RELIABILITY]` - Reliability requirements
- `[REQ:MAINTAINABILITY]` - Maintainability requirements
- `[REQ:USABILITY]` - Usability requirements

## Architecture Tokens

### Core Architecture Decisions
- `[ARCH:LANGUAGE_SELECTION]` - Language and runtime selection
- `[ARCH:PROJECT_STRUCTURE]` - Project structure decision
- `[ARCH:SHEBANG_EXTRACTION]` - Extract shebang lines during cached nested read [REQ:SHEBANG_HIDING]
- `[ARCH:CLI_OPTION_DESIGN]` - CLI option design for shebang hiding [REQ:SHEBANG_HIDING]
- `[ARCH:EXAMPLE_DECISION]` - Example architecture decision [REQ:EXAMPLE_FEATURE]
- Add your architecture tokens here

## Implementation Tokens

### Core Implementation Decisions
- `[IMPL:CONFIG_STRUCT]` - Configuration structure implementation [ARCH:CONFIG_STRUCTURE] [REQ:CONFIGURATION]
- `[IMPL:SHEBANG_DETECTION]` - Shebang line detection logic [ARCH:SHEBANG_EXTRACTION] [REQ:SHEBANG_HIDING]
- `[IMPL:SHEBANG_FILTERING]` - Filter shebang lines from processed output [ARCH:SHEBANG_EXTRACTION] [REQ:SHEBANG_HIDING]
- `[IMPL:CLI_OPTION_IMPLEMENTATION]` - CLI option implementation in menu system [ARCH:CLI_OPTION_DESIGN] [REQ:SHEBANG_HIDING]
- `[IMPL:EXAMPLE_IMPLEMENTATION]` - Example implementation [ARCH:EXAMPLE_DECISION] [REQ:EXAMPLE_FEATURE]
- Add your implementation tokens here

## Test Tokens

### Test Specifications
- `[TEST:SHELL_COMMAND]` - Comprehensive test suite for ShellCommand class covering execution, memoization, outputs, metadata, and edge cases
- Add your test tokens here

## Token Relationships

### Hierarchical Relationships
- `[REQ:PARENT_FEATURE]` contains `[REQ:SUB_FEATURE_1]`, `[REQ:SUB_FEATURE_2]`
- `[ARCH:FEATURE]` includes `[ARCH:COMPONENT_1]`, `[ARCH:COMPONENT_2]`

### Flow Relationships
- `[REQ:FEATURE]` → `[ARCH:DESIGN]` → `[IMPL:IMPLEMENTATION]` → Code + Tests

### Dependency Relationships
- `[IMPL:FEATURE]` depends on `[ARCH:DESIGN]` and `[REQ:FEATURE]`
- `[ARCH:DESIGN]` depends on `[REQ:FEATURE]`

## Usage Examples

### In Code Comments
```[your-language]
// [REQ:EXAMPLE_FEATURE] Implementation of example feature
// [IMPL:EXAMPLE_IMPLEMENTATION] [ARCH:EXAMPLE_DECISION] [REQ:EXAMPLE_FEATURE]
function exampleFunction() {
    // ...
}
```

### In Tests
```[your-language]
// Test validates [REQ:EXAMPLE_FEATURE] is met
func TestExampleFeature_REQ_EXAMPLE_FEATURE(t *testing.T) {
    // ...
}
```

### In Documentation
```markdown
The feature uses [ARCH:EXAMPLE_DECISION] to fulfill [REQ:EXAMPLE_FEATURE].
Implementation details are documented in [IMPL:EXAMPLE_IMPLEMENTATION].
```

## Token Index by Category

### Requirements
- `[REQ:SHEBANG_HIDING]` - CLI option to hide shebang lines in document output
- Add your requirement tokens here

### Architecture
- `[ARCH:SHEBANG_EXTRACTION]` - Extract shebang lines during cached nested read
- `[ARCH:CLI_OPTION_DESIGN]` - CLI option design for shebang hiding
- Add your architecture tokens here

### Implementation
- `[IMPL:SHEBANG_DETECTION]` - Shebang line detection logic
- `[IMPL:SHEBANG_FILTERING]` - Filter shebang lines from processed output
- `[IMPL:CLI_OPTION_IMPLEMENTATION]` - CLI option implementation in menu system
- Add your implementation tokens here

### Tests
- `[TEST:SHELL_COMMAND]` - Comprehensive test suite for ExecutedShellCommand class
- Add your test tokens here

