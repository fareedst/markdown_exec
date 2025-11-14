# Implementation Decisions

**STDD Methodology Version**: 1.0.0

## Overview
This document captures detailed implementation decisions for your project, including specific APIs, data structures, and algorithms. All decisions are cross-referenced with architecture decisions using `[ARCH:*]` tokens and requirements using `[REQ:*]` tokens for traceability.

## 1. Configuration Structure [IMPL:CONFIG_STRUCT] [ARCH:CONFIG_STRUCTURE] [REQ:CONFIGURATION]

### Config Type
```[your-language]
type Config struct {
    // Add your configuration fields here
    Field1 string
    Field2 int
    Field3 bool
}
```

### Default Values
- Field1: default value
- Field2: default value
- Field3: default value

## 2. Core Implementation [IMPL:EXAMPLE_IMPLEMENTATION] [ARCH:EXAMPLE_DECISION] [REQ:EXAMPLE_FEATURE]

### Data Structure
```[your-language]
type ExampleStruct struct {
    Field1 string
    Field2 int
}
```

### Implementation Approach
- Approach description
- Key algorithms
- Performance considerations

### Platform-Specific Considerations
- Platform 1: Specific considerations
- Platform 2: Specific considerations

## 3. Error Handling Implementation [IMPL:ERROR_HANDLING] [ARCH:ERROR_HANDLING] [REQ:ERROR_HANDLING]

### Error Types
```[your-language]
var (
    ErrExampleError = errors.New("example error message")
    ErrAnotherError = errors.New("another error message")
)
```

### Error Wrapping
```[your-language]
if err != nil {
    return fmt.Errorf("context: %w", err)
}
```

### Error Reporting
- Error logging approach
- Error propagation pattern
- User-facing error messages

## 4. Testing Implementation [IMPL:TESTING] [ARCH:TESTING_STRATEGY] [REQ:*]

**Note**: This implementation realizes the validation criteria specified in `requirements.md` and follows the testing strategy defined in `architecture-decisions.md`. Each test validates specific satisfaction criteria from requirements.

### Unit Test Structure
```[your-language]
func TestExampleFeature(t *testing.T) {
    tests := []struct {
        name     string
        input    InputType
        expected OutputType
    }{
        {
            name:     "test case 1",
            input:    inputValue,
            expected: expectedValue,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := functionUnderTest(tt.input)
            if result != tt.expected {
                t.Errorf("expected %v, got %v", tt.expected, result)
            }
        })
    }
}
```

### Integration Test Structure
```[your-language]
func TestIntegrationScenario(t *testing.T) {
    // Setup
    // Execute
    // Verify
}
```

## 5. Code Style and Conventions [IMPL:CODE_STYLE]

### Naming
- Use descriptive names
- Follow language naming conventions
- Exported types/functions: PascalCase (or language equivalent)
- Unexported: camelCase (or language equivalent)

### Documentation
- Package-level documentation
- Exported function documentation
- Inline comments for complex logic
- Examples in test files

### Formatting
- Use standard formatter for chosen language
- Use linter for code quality

## 6. Shebang Line Detection Logic [IMPL:SHEBANG_DETECTION] [ARCH:SHEBANG_EXTRACTION] [REQ:SHEBANG_HIDING]

### Detection Algorithm
```ruby
  # [REQ:SHEBANG_HIDING] Detect shebang lines at the start of file content
  # [IMPL:SHEBANG_DETECTION] [ARCH:SHEBANG_EXTRACTION] [REQ:SHEBANG_HIDING]
  # Matches the beginning of the first line as '#!' - anything after that matches a shebang
  # Works directly with raw string segments (not NestedLine objects)
  def is_shebang_line?(line, is_first_line)
    return false unless is_first_line
    line.start_with?('#!')
  end
```

### Detection Rules
- Shebang lines must start with `#!` at the beginning of the line (no leading whitespace)
- Only the first line of file content is considered (index 0)
- The line must begin with `#!` - anything after that matches a shebang
- Detection occurs before import directive processing
- Each file in nested imports is checked independently

### Edge Cases
- Empty files: No shebang (no first line)
- Files starting with whitespace before `#!`: Not recognized as shebang (must be at beginning)
- Files with only shebang: File becomes effectively empty after filtering
- Import directives on first line: Shebang takes precedence (shebang is first)

## 7. Shebang Line Filtering Implementation [IMPL:SHEBANG_FILTERING] [ARCH:SHEBANG_EXTRACTION] [REQ:SHEBANG_HIDING]

### Filtering Logic
```ruby
# [REQ:SHEBANG_HIDING] Filter shebang lines from processed output
# [IMPL:SHEBANG_FILTERING] [ARCH:SHEBANG_EXTRACTION] [REQ:SHEBANG_HIDING]
# Filtering occurs inline during segment reading
File.readlines(filename, chomp: true).each.with_index do |segment, ind|
  # Skip shebang lines at the beginning of the file
  next if @hide_shebang && is_shebang_line?(segment, ind == 0)
  
  # Process remaining lines normally
  # ...
end
```

### Implementation Details
- Filtering occurs inline in `CachedNestedFileReader#readlines` during segment reading
- Shebang lines are skipped before they are processed into `NestedLine` objects
- Applied to both direct file reads and nested imports (via recursive calls)
- Option `hide_shebang` controls filtering behavior
- When disabled (`hide_shebang: false`), all lines included
- When enabled (`hide_shebang: true`), first line (index 0) is skipped if it's a shebang
- Filtering happens at the source, preventing shebang lines from entering the processing pipeline
- More efficient than post-processing as it avoids creating `NestedLine` objects for shebang lines

### Integration with CachedNestedFileReader
- Option stored as instance variable `@hide_shebang` set during initialization
- Filtering applied inline during the `File.readlines` loop before segment processing
- Shebang detection uses `is_shebang_line?(segment, ind == 0)` where `segment` is the raw string line
- Cached results already have shebang filtered (if option was enabled during cache)
- Recursive calls to `readlines` use the same `@hide_shebang` instance variable, ensuring consistent behavior across nested imports

## 8. CLI Option Implementation in Menu System [IMPL:CLI_OPTION_IMPLEMENTATION] [ARCH:CLI_OPTION_DESIGN] [REQ:SHEBANG_HIDING]

### Menu Configuration
```yaml
# [REQ:SHEBANG_HIDING] CLI option for hiding shebang lines
# [IMPL:CLI_OPTION_IMPLEMENTATION] [ARCH:CLI_OPTION_DESIGN] [REQ:SHEBANG_HIDING]
- :opt_name: hide_shebang
  :env_var: MDE_HIDE_SHEBANG
  :description: Hide shebang lines in document output
  :arg_name: BOOL
  :default: true
  :procname: val_as_bool
```

### Option Access
- CLI: `--hide-shebang` (enables) / `--no-hide-shebang` (disables)
- Environment: `MDE_HIDE_SHEBANG=true` or `MDE_HIDE_SHEBANG=false`
- Configuration file: `hide_shebang: true` in `.mde.yml`
- Default: `true` (shebang lines hidden by default)

### Option Propagation
- Option available in `@options` hash via `MarkParse#base_options`
- Option passed to `CachedNestedFileReader` during initialization or read calls
- Option value accessible as `options[:hide_shebang]` (boolean)

### Integration Points
- `MarkParse#base_options`: Includes option in base options hash
- `CachedNestedFileReader#initialize`: Option passed as parameter (or via options hash)
- `CachedNestedFileReader#readlines`: Option used to control filtering behavior

