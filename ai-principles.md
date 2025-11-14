# AI-First Principles & Process Guide

**Purpose**: This document defines the principles, processes, and conventions that AI agents must follow when working on this project. It should be referenced at the start of every AI agent interaction.

## 🎯 Semantic Token-Driven Development (STDD)

This project follows **Semantic Token-Driven Development (STDD)**, a methodology where semantic tokens (`[REQ:*]`, `[ARCH:*]`, `[IMPL:*]`) are the central mechanism for preserving intent throughout the entire development lifecycle.

### How Semantic Tokens Preserve Intent

Semantic tokens create a **traceable chain of intent** that ensures the original purpose and reasoning are never lost:

1. **Requirements** (`[REQ:*]`) define the "what" and "why" - the original intent
2. **Architecture** decisions (`[ARCH:*]`) explain the "how" at a high level and link back to requirements via cross-references
3. **Implementation** decisions (`[IMPL:*]`) explain the "how" at a low level and link back to both architecture and requirements
4. **Tests** validate requirements are met, referencing the same tokens in test names and comments
5. **Code** comments include tokens, maintaining the connection to original intent

This creates a **living documentation system** where:
- Every decision can be traced back to its requirement
- The reasoning behind architectural choices is preserved
- Implementation details remain connected to their purpose
- Tests explicitly validate the original intent
- Code comments maintain context even as the codebase evolves

**Semantic tokens are not just labels—they are the mechanism that preserves intent from requirements through architecture, implementation, tests, and code.**

## ⚠️ MANDATORY ACKNOWLEDGMENT

**AI AGENTS MUST** acknowledge adherence to these principles at the start of EVERY response by prefacing with:

**"Observing AI principles!"**

This acknowledgment confirms that the AI agent has:
- Read and understood this document
- Will follow all documented processes
- Will use semantic tokens consistently
- Will prioritize tasks correctly

---

## 📋 Table of Contents

1. [Semantic Token-Driven Development (STDD)](#-semantic-token-driven-development-stdd)
2. [AI-First Principles](#ai-first-principles)
3. [Documentation Structure](#documentation-structure)
4. [Semantic Token System](#semantic-token-system)
5. [Development Process](#development-process)
6. [Task Tracking System](#task-tracking-system)
7. [How to Present This to AI Agents](#how-to-present-this-to-ai-agents)

---

## 🤖 AI-First Principles

### Core Principles

1. **Semantic Token Cross-Referencing**
   - All code, tests, requirements, architecture decisions, and implementation decisions MUST be cross-referenced using semantic tokens (e.g., `[REQ:FEATURE]`, `[IMPL:IMPLEMENTATION]`).
   - Semantic tokens provide traceability from requirements → architecture → implementation → tests.

2. **Documentation-First Development**
   - Requirements MUST be expanded into pseudo-code and architectural decisions before implementation.
   - No code changes until requirements are fully specified with semantic tokens.

3. **Test-Driven Documentation**
   - Tests MUST reference the requirements they validate using semantic tokens.
   - Test names should include semantic tokens (e.g., `TestDuplicatePrevention_REQ_DUPLICATE_PREVENTION`).

4. **Incremental Task Tracking**
   - Every requirement implementation MUST be broken down into trackable tasks and subtasks.
   - Tasks have explicit priorities: **P0 (Critical)** > **P1 (Important)** > **P2 (Nice-to-have)** > **P3 (Future)**.

5. **Priority-Based Implementation**
   - **Most Important**: Tests, Code, Basic Functions
   - **Least Important**: Environment Orchestration, Enhanced Security, Automated Deployment

6. **Complete Task Completion**
   - When all subtasks for a task are complete, remove subtasks and mark the parent task complete.
   - Maintain a clean task list showing only active work.

---

## 📚 Documentation Structure

### Required Documentation Sections

All project documentation MUST include these sections with semantic token cross-references:

#### 1. Requirements Section
- Lists all functional and non-functional requirements
- Each requirement has a unique semantic token: `[REQ:IDENTIFIER]`
- Each requirement includes:
  - **Description**: What the requirement specifies
  - **Rationale**: Why the requirement exists
  - **Satisfaction Criteria**: How we know the requirement is satisfied (acceptance criteria, success conditions)
  - **Validation Criteria**: How we verify/validate the requirement is met (testing approach, verification methods, success metrics)
- Example: `[REQ:FEATURE] Description of the feature requirement`
- Implementation status: ✅ (Implemented) or ⏳ (Planned)
- **Note**: Validation criteria defined in requirements inform the testing strategy in `architecture-decisions.md` and specific test implementations in `implementation-decisions.md`

#### 2. Architecture Decisions Section
- Documents high-level design choices
- **Location**: `architecture-decisions.md` - dedicated file for architecture decisions
- **MANDATORY**: Must be updated IMMEDIATELY when architectural decisions are made
- **DO NOT** defer architecture documentation - record decisions as they are made
- Links to requirements via semantic tokens
- Each decision MUST include semantic token `[ARCH:IDENTIFIER]` and cross-reference to `[REQ:*]` tokens
- Example: `[ARCH:CONCURRENCY_MODEL] Uses goroutines with WaitGroup for async execution [REQ:ASYNC_EXECUTION]`
- **Dependency**: Architecture decisions depend on requirements and should reference `[REQ:*]` tokens
- **Update Timing**: Record in `architecture-decisions.md` during Phase 1 (Requirements → Pseudo-Code) and update as decisions evolve

#### 3. Implementation Decisions Section
- Documents low-level implementation choices
- **Location**: `implementation-decisions.md` - dedicated file for implementation decisions
- **MANDATORY**: Must be updated IMMEDIATELY when implementation decisions are made
- **DO NOT** defer implementation documentation - record decisions as they are made
- Links to requirements and architecture via semantic tokens
- Each decision MUST include semantic token `[IMPL:IDENTIFIER]` and cross-reference to `[ARCH:*]` and `[REQ:*]` tokens
- Example: `[IMPL:DUPLICATE_PREVENTION] Track lastText string [ARCH:STATE_TRACKING] [REQ:DUPLICATE_PREVENTION]`
- **Dependency**: Implementation decisions depend on both architecture decisions and requirements
- **Update Timing**: Record in `implementation-decisions.md` during Phase 1 (Requirements → Pseudo-Code) and update during Phase 3 (Implementation) as decisions are refined

#### 4. Semantic Token Registry
- Central registry of all semantic tokens used in the project
- Maps tokens to their definitions and cross-references

#### 5. Code References
- Code comments MUST include semantic tokens
- Example: `// [REQ:DUPLICATE_PREVENTION] Skip if text matches lastText`

#### 6. Test References
- Test names and comments MUST include semantic tokens
- Example: `func TestDuplicatePrevention_REQ_DUPLICATE_PREVENTION(t *testing.T)`

---

## 🏷️ Semantic Token System

**Semantic tokens are the foundation of STDD** - they are the mechanism that preserves intent throughout the development lifecycle.

### Token Format

```
[TYPE:IDENTIFIER]
```

### Token Types

- `[REQ:*]` - Requirements (functional/non-functional) - **The source of intent**
- `[ARCH:*]` - Architecture decisions - **High-level design choices that preserve intent**
- `[IMPL:*]` - Implementation decisions - **Low-level choices that preserve intent**
- `[TEST:*]` - Test specifications - **Validation of intent**
- `[CLI/Config]` - Configuration/CLI related
- `[OS Integration]` - OS-specific integration
- `[Logging]` - Logging related
- `[Testability]` - Testability concerns
- `[Security]` - Security considerations

### Intent Preservation Through Tokens

Each token type serves a specific role in preserving intent:

- **`[REQ:*]` tokens** capture the original "what" and "why" - the fundamental intent
- **`[ARCH:*]` tokens** document how high-level design choices fulfill requirements, maintaining the connection to intent
- **`[IMPL:*]` tokens** document how low-level implementation choices fulfill architecture and requirements, preserving the reasoning
- **Cross-references** (`[ARCH:X] [REQ:Y]`) create explicit links that maintain traceability
- **Test names** (`TestFeature_REQ_FEATURE`) explicitly validate that intent is preserved
- **Code comments** (`// [REQ:FEATURE] Implementation`) maintain context even as code evolves

### Token Naming Convention

- Use UPPER_SNAKE_CASE for identifiers
- Be descriptive but concise
- Example: `[REQ:DUPLICATE_PREVENTION]` not `[REQ:DP]`

### Cross-Reference Format

When referencing other tokens:

```markdown
[IMPL:DUPLICATE_PREVENTION] Track lastText string [REQ:DUPLICATE_PREVENTION]
```

### Token Registry Location

Create and maintain `semantic-tokens.md` with:
- All tokens used in the project
- Definitions
- Cross-reference mappings
- Status (Implemented/Planned)

---

## 🔄 Development Process

### Phase 1: Requirements → Pseudo-Code

**MANDATORY**: Before any code changes, expand requirements into pseudo-code and decisions.

1. **Identify Requirement**
   - Extract requirement from documentation
   - Note semantic token: `[REQ:IDENTIFIER]`

2. **Architectural Decisions** (MANDATORY - Record IMMEDIATELY)
   - **IMMEDIATELY** document high-level approach in `architecture-decisions.md`
   - **IMMEDIATELY** create `[ARCH:IDENTIFIER]` tokens
   - **IMMEDIATELY** cross-reference: `[ARCH:IDENTIFIER] [REQ:IDENTIFIER]`
   - Each architecture decision MUST be recorded in `architecture-decisions.md` with semantic token links
   - Architecture decisions are dependent on requirements and must reference `[REQ:*]` tokens
   - **DO NOT** defer - record decisions as they are made, not at the end

3. **Implementation Decisions** (MANDATORY - Record IMMEDIATELY)
   - **IMMEDIATELY** document low-level approach in `implementation-decisions.md`
   - **IMMEDIATELY** create `[IMPL:IDENTIFIER]` tokens
   - **IMMEDIATELY** cross-reference: `[IMPL:IDENTIFIER] [ARCH:IDENTIFIER] [REQ:IDENTIFIER]`
   - Each implementation decision MUST be recorded in `implementation-decisions.md` with semantic token links
   - Implementation decisions are dependent on both architecture decisions and requirements
   - **DO NOT** defer - record decisions as they are made, not at the end

4. **Pseudo-Code**
   - Write pseudo-code with semantic token comments
   - Example:
     ```text
     // [REQ:DUPLICATE_PREVENTION]
     if text == lastText:
       skip()
     ```

5. **Update Documentation** (MANDATORY - Do IMMEDIATELY)
   - **IMMEDIATELY** add architecture decisions to `architecture-decisions.md` with `[ARCH:*]` tokens and `[REQ:*]` cross-references
   - **IMMEDIATELY** add implementation decisions to `implementation-decisions.md` with `[IMPL:*]` tokens and `[ARCH:*]` and `[REQ:*]` cross-references
   - **IMMEDIATELY** update `semantic-tokens.md` with any new tokens created
   - **IMMEDIATELY** create tasks in `tasks.md` with priorities and semantic token references
   - Cross-reference all tokens consistently
   - **DO NOT** defer documentation updates - they are part of the planning phase

### Phase 2: Pseudo-Code → Tasks (MANDATORY - Plan BEFORE Implementation)

1. **Generate Tasks** (MANDATORY - Record in `tasks.md`)
   - **IMMEDIATELY** break down into discrete tasks in `tasks.md`
   - Each task MUST reference semantic tokens
   - Example: `Task: Implement duplicate prevention [REQ:DUPLICATE_PREVENTION]`
   - **DO NOT** start implementation until tasks are documented

2. **Generate Subtasks** (MANDATORY - Record in `tasks.md`)
   - **IMMEDIATELY** break tasks into implementable subtasks in `tasks.md`
   - Each subtask is a single, complete unit of work
   - Example:
     - Subtask: Add field to data structure
     - Subtask: Implement `isDuplicate()` function
     - Subtask: Call `isDuplicate()` in polling loop
     - Subtask: Write test `TestDuplicatePrevention_REQ_DUPLICATE_PREVENTION`
   - **DO NOT** start implementation until subtasks are documented

3. **Assign Priorities** (MANDATORY - Required for all tasks)
   - P0: Critical (blocks core functionality)
   - P1: Important (enhances functionality)
   - P2: Nice-to-have (improves UX/developer experience)
   - P3: Future (deferred)
   - **ALL tasks MUST have priorities assigned**

### Phase 3: Tasks → Implementation

1. **Work on Highest Priority Tasks First**
   - P0 tasks before P1, P1 before P2, etc.

2. **Complete Subtasks**
   - Mark subtasks complete as they're done
   - Remove completed subtasks
   - When all subtasks complete, mark parent task complete

3. **Update Documentation** (MANDATORY - Update AS YOU WORK)
   - **DURING implementation**: Update `architecture-decisions.md` if decisions are refined
   - **DURING implementation**: Update `implementation-decisions.md` if decisions are refined
   - **DURING implementation**: Update `tasks.md` as subtasks are completed
   - **AFTER completion**: Mark requirements as ✅ Implemented
   - **AFTER completion**: Update code with semantic token comments
   - **AFTER completion**: Update tests with semantic token references
   - **AFTER completion**: Verify all documentation is current and accurate

---

## 📝 Task Tracking System

### Task Format

```markdown
## P0: Task Name [REQ:IDENTIFIER] [ARCH:IDENTIFIER] [IMPL:IDENTIFIER]

**Status**: 🟡 In Progress | ✅ Complete | ⏸️ Blocked | ⏳ Pending

**Description**: Brief description of what this task accomplishes.

**Dependencies**: List of other tasks/tokens this depends on.

**Subtasks**:
- [ ] Subtask 1 [REQ:X] [IMPL:Y]
- [ ] Subtask 2 [REQ:X] [IMPL:Z]
- [ ] Subtask 3 [TEST:X]

**Completion Criteria**:
- [ ] All subtasks complete
- [ ] Code implements requirement
- [ ] Tests pass with semantic token references
- [ ] Documentation updated

**Priority Rationale**: Why this is P0/P1/P2/P3
```

### Task Management Rules

1. **Subtasks are Temporary**
   - Subtasks exist only while the parent task is in progress
   - Remove subtasks when parent task completes

2. **Priority Must Be Justified**
   - Each task must have a priority rationale
   - Priorities follow: Tests/Code/Functions > DX > Infrastructure > Security

3. **Semantic Token References Required**
   - Every task MUST reference at least one semantic token
   - Cross-reference to related tokens

4. **Completion Criteria Must Be Met**
   - All criteria must be checked before marking complete
   - Documentation must be updated

### Task Status Icons

- 🟡 **In Progress**: Actively being worked on
- ✅ **Complete**: All criteria met, subtasks removed
- ⏸️ **Blocked**: Waiting on dependency
- ⏳ **Pending**: Not yet started

### Priority Levels

#### P0: Critical (Must Have)
- Core functionality
- Tests that validate requirements
- Basic working features
- Blocks other work

#### P1: Important (Should Have)
- Enhanced functionality
- Better error handling
- Performance improvements
- Developer experience

#### P2: Nice-to-Have (Could Have)
- UI/UX improvements
- Documentation enhancements
- Convenience features
- Non-critical optimizations

#### P3: Future (Won't Have Now)
- Deferred features
- Experimental ideas
- Future enhancements
- Infrastructure improvements

---

## 📖 How to Present This to AI Agents

### Method 1: Include in System Prompt

When starting a new AI agent session, include:

```
MANDATORY: At the start of EVERY response, you MUST preface with:
"Observing AI principles!"

Then proceed to:
1. Read and follow the AI-First Principles document (ai-principles.md) 
2. Use semantic tokens [REQ:*], [ARCH:*], [IMPL:*] throughout
3. Expand requirements into pseudo-code before coding
4. Break work into trackable tasks with priorities
5. Cross-reference everything using semantic tokens
6. Prioritize: Tests > Code > Basic Functions > Infrastructure
```

### Method 2: Include in .cursorrules (Already Configured)

The `.cursorrules` file in the project root is automatically loaded by Cursor IDE and contains these instructions. The acknowledgment requirement is already embedded.

### Method 3: Reference in User Query

Start requests with:

```
Following ai-principles.md, please:
[your request here]
```

The AI agent should acknowledge with "Observing AI principles!" and then proceed.

### Method 4: .cursorrules File (Already Configured)

The `.cursorrules` file in the project root is automatically loaded by Cursor IDE. It includes:
- Mandatory acknowledgment requirement
- Complete rules and principles
- Workflow examples

**Already configured in this project!**

### Method 5: Include in README.md

Add section to README.md:

```markdown
## For AI Agents

This project follows AI-First Principles. Before making changes:

1. Read `ai-principles.md`
2. Use semantic tokens for cross-referencing
3. Expand requirements into pseudo-code before implementation
4. Create tasks with priorities
5. Follow priority order: Tests > Code > Functions > Infrastructure
```

---

## ✅ Checklist for AI Agents

**AT THE START OF EVERY RESPONSE:**

- [ ] **MANDATORY**: Preface response with "Observing AI principles!"
- [ ] Read `ai-principles.md` (if not already read in this session)
- [ ] Check `semantic-tokens.md` for existing tokens
- [ ] Review `tasks.md` for active tasks
- [ ] Understand semantic token system
- [ ] Know the development process
- [ ] Understand priority levels

**BEFORE STARTING ANY WORK:**

- [ ] Verify all prerequisites above
- [ ] Have access to semantic token registry
- [ ] Understand current task priorities
- [ ] **MANDATORY**: Review `architecture-decisions.md` for existing architecture decisions
- [ ] **MANDATORY**: Review `implementation-decisions.md` for existing implementation decisions
- [ ] **MANDATORY**: Plan work in `tasks.md` BEFORE writing any code

**DURING WORK:**

- [ ] Use semantic tokens in all code comments
- [ ] Use semantic tokens in test names/comments
- [ ] Cross-reference requirements → architecture → implementation
- [ ] **MANDATORY**: Record architecture decisions in `architecture-decisions.md` IMMEDIATELY when made (with `[ARCH:*]` tokens and `[REQ:*]` cross-references)
- [ ] **MANDATORY**: Record implementation decisions in `implementation-decisions.md` IMMEDIATELY when made (with `[IMPL:*]` tokens and `[ARCH:*]` and `[REQ:*]` cross-references)
- [ ] **MANDATORY**: Break work into trackable tasks in `tasks.md` BEFORE starting implementation
- [ ] **MANDATORY**: Assign appropriate priorities to all tasks
- [ ] **MANDATORY**: Update `tasks.md` as subtasks are completed
- [ ] **MANDATORY**: Update `semantic-tokens.md` when creating new tokens
- [ ] **MANDATORY**: Update documentation AS YOU WORK - do not defer until the end

**AFTER COMPLETING WORK:**

- [ ] **MANDATORY**: All semantic tokens documented in `semantic-tokens.md`
- [ ] **MANDATORY**: Documentation updated with implementation status:
  - `architecture-decisions.md` reflects all architectural decisions made
  - `implementation-decisions.md` reflects all implementation decisions made
  - Both cross-reference `[REQ:*]` tokens correctly
- [ ] **MANDATORY**: Tests reference semantic tokens
- [ ] **MANDATORY**: Tasks marked complete in `tasks.md`
- [ ] **MANDATORY**: Subtasks removed from completed tasks
- [ ] **MANDATORY**: All documentation is current and accurate (no stale information)
- [ ] **MANDATORY**: Verify documentation completeness before marking work complete

---

## 📚 Related Documents

- `requirements.md` - Main design document with requirements (copy from `requirements.template.md` in STDD repository)
- `architecture-decisions.md` - **Semantic-token-linked record of architecture decisions dependent on requirements** (copy from `architecture-decisions.template.md`)
  - All `[ARCH:*]` tokens must be documented here
  - Must cross-reference `[REQ:*]` tokens from requirements
- `implementation-decisions.md` - **Semantic-token-linked record of implementation decisions dependent on architecture and requirements** (copy from `implementation-decisions.template.md`)
  - All `[IMPL:*]` tokens must be documented here
  - Must cross-reference both `[ARCH:*]` and `[REQ:*]` tokens
- `semantic-tokens.md` - Central registry of all semantic tokens (copy from `semantic-tokens.template.md`)
- `tasks.md` - Active task tracking document (copy from `tasks.template.md`)
- `README.md` - Project overview and getting started guide

---

## 🔄 Maintenance

This document should be:
- Reviewed when adding new requirements
- Updated when adding new semantic token types
- Referenced at the start of every AI agent session
- Used as a checklist for all development work

## ⚠️ CRITICAL REMINDERS

### Documentation is MANDATORY, Not Optional

1. **Architecture Decisions**: Record IMMEDIATELY in `architecture-decisions.md` when made
2. **Implementation Decisions**: Record IMMEDIATELY in `implementation-decisions.md` when made
3. **Task Planning**: Plan in `tasks.md` BEFORE starting implementation
4. **Semantic Tokens**: Update `semantic-tokens.md` when creating new tokens
5. **DO NOT DEFER**: Documentation updates are part of the work, not something to do "later"

### Documentation Update Timing

- **Planning Phase**: Document architecture and implementation decisions
- **Implementation Phase**: Update documentation as decisions are refined
- **Completion Phase**: Verify all documentation is current and complete

**Last Updated**: 2025-11-08
**Version**: 1.0.0
**STDD Methodology Version**: 1.0.0

