# Architecture Decisions

**STDD Methodology Version**: 1.0.0

## Overview
This document captures the high-level architectural decisions for your project. All decisions are cross-referenced with requirements using semantic tokens `[REQ:*]` and assigned architecture tokens `[ARCH:*]` for traceability.

## 1. Language and Runtime [ARCH:LANGUAGE_SELECTION]

### Decision: [Your Language/Runtime Choice]
**Rationale:**
- Reason 1
- Reason 2
- Reason 3

**Alternatives Considered:**
- Alternative 1: Why it was rejected
- Alternative 2: Why it was rejected

## 2. Project Structure [ARCH:PROJECT_STRUCTURE]

### Decision: [Your Project Structure]
```
project-root/
├── src/                    # Source code
├── tests/                   # Test files
├── docs/                    # Documentation
└── config/                  # Configuration files
```

**Rationale:**
- Clear separation of concerns
- Standard project layout
- Testable components

## 3. Core Architecture Decision [ARCH:EXAMPLE_DECISION] [REQ:EXAMPLE_FEATURE]

### Decision: [Your Architecture Choice]
**Rationale:**
- Matches requirement [REQ:EXAMPLE_FEATURE]
- Provides benefits X, Y, Z
- Simpler implementation

**Alternatives Considered:**
- Alternative approach: More complex, less maintainable

**Implementation:**
- High-level approach
- Key components
- Integration points

## 4. Data Management [ARCH:DATA_MANAGEMENT] [REQ:DATA_REQUIREMENT]

### Decision: [Your Data Management Approach]
**Rationale:**
- Reason 1
- Reason 2

**Implementation:**
- Storage approach
- Data access patterns
- Consistency model

## 5. Error Handling Strategy [ARCH:ERROR_HANDLING] [REQ:ERROR_HANDLING]

### Decision: [Your Error Handling Approach]
**Rationale:**
- Idiomatic for chosen language/framework
- Clear error propagation
- Easy to test

**Pattern:**
- Error types
- Error propagation
- Error reporting

## 6. Testing Strategy [ARCH:TESTING_STRATEGY]

### Decision: [Your Testing Approach]
**Rationale:**
- Comprehensive test coverage
- Fast unit tests
- Integration tests for end-to-end scenarios
- Aligns with validation criteria defined in requirements [REQ:*]

**Structure:**
- Unit test organization
- Integration test organization
- Test fixtures and utilities

**Note**: This testing strategy implements the validation criteria specified in `requirements.md`. Each requirement's validation criteria informs what types of tests are needed (unit, integration, manual verification, etc.).

## 7. Dependency Management [ARCH:DEPENDENCY_MANAGEMENT]

### Decision: [Your Dependency Management Approach]
**Rationale:**
- Reduce external dependencies
- Faster builds
- Fewer security concerns

**Allowed Dependencies:**
- Standard library only (or minimal external dependencies)
- Consider external packages only if standard library is insufficient

## 8. Build and Distribution [ARCH:BUILD_DISTRIBUTION]

### Decision: [Your Build and Distribution Approach]
**Rationale:**
- Easy deployment
- No runtime dependencies
- Cross-platform support

**Build Targets:**
- Platform 1
- Platform 2
- Platform 3

## 9. Code Organization Principles [ARCH:CODE_ORGANIZATION]

### Decision: [Your Code Organization Approach]
**Rationale:**
- Testable components
- Clear responsibilities
- Easy to extend
- Maintainable codebase

**Principles:**
- Each module has a single, clear responsibility
- Functions are small and focused
- Interfaces where appropriate for testability
- Avoid global state where possible

## 10. Shebang Line Extraction During Cached Nested Read [ARCH:SHEBANG_EXTRACTION] [REQ:SHEBANG_HIDING]

### Decision: Extract shebang lines during the cached nested file read process
**Rationale:**
- Matches requirement [REQ:SHEBANG_HIDING] to extract shebang lines during cached nested read
- Centralizes file processing logic in `CachedNestedFileReader`
- Ensures consistent behavior across all file reads (including nested imports)
- Leverages existing file caching mechanism to avoid re-processing
- Single point of control for shebang handling simplifies maintenance

**Alternatives Considered:**
- Post-processing filter: More complex, requires additional pass over processed lines
- Separate shebang extraction pass: Less efficient, duplicates file reading
- Per-component filtering: Inconsistent behavior, harder to maintain

**Implementation:**
- Modify `CachedNestedFileReader#readlines` to detect and filter shebang lines inline during segment reading
- Shebang detection: Lines starting with `#!` at the beginning of file content (first line, index 0)
- Filtering occurs before segments are processed into `NestedLine` objects, improving efficiency
- Filtering controlled by CLI option stored as instance variable `@hide_shebang` in `CachedNestedFileReader`
- Apply filtering recursively to nested imports (same instance variable used in recursive calls)

**Integration Points:**
- `CachedNestedFileReader` receives option via `hide_shebang` parameter during initialization
- Option stored as `@hide_shebang` instance variable
- Filtering applied inline during `File.readlines` loop using `next` to skip shebang segments
- Filtered segments never enter the processing pipeline, ensuring they don't appear in `processed_lines` array

## 11. CLI Option Design for Shebang Hiding [ARCH:CLI_OPTION_DESIGN] [REQ:SHEBANG_HIDING]

### Decision: Add CLI option `hide_shebang` (default: true) to control shebang line visibility
**Rationale:**
- Matches requirement [REQ:SHEBANG_HIDING] for CLI option with default enabled
- Follows existing CLI option patterns in MDE (see `menu.src.yml`)
- Default enabled provides better UX (most users don't want shebang in output)
- Option name `hide_shebang` is clear and descriptive
- Supports both CLI flag and environment variable (consistent with MDE patterns)

**Alternatives Considered:**
- `show_shebang` (default: false): Less intuitive, requires negation logic
- `no_hide_shebang`: Double negative is confusing
- `include_shebang` (default: false): Less clear about default behavior

**Implementation:**
- Add option to `menu.src.yml` with:
  - `opt_name: hide_shebang`
  - `env_var: MDE_HIDE_SHEBANG`
  - `default: true`
  - `procname: val_as_bool`
- Option accessible via `--hide-shebang` / `--no-hide-shebang` flags
- Option accessible via `MDE_HIDE_SHEBANG` environment variable
- Option passed to `CachedNestedFileReader` during initialization or read calls

**Integration Points:**
- `MarkParse#base_options` includes the option
- `CachedNestedFileReader` receives option value
- Option value controls filtering behavior in `readlines` method

