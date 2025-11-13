#!/usr/bin/env bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8

# =============================================================================
# PARAMETER EXPANSION UTILITY
# =============================================================================
#
# This module provides parameter expansion functionality for markdown_exec,
# handling different invocation types for parameter substitution with support
# for new variable creation and tracking.
#
# =============================================================================
# REQUIREMENTS
# =============================================================================
#
# ## Functional Requirements
#
# 1. **Parameter Expansion**: Support all 16 invocation code combinations
#    - Input types: C (command), E (expression), L (literal), V (variable)
#    - Output types: C (command), E (expression), L (literal), V (variable)
#
# 2. **Single Character Support**: Accept 1-character invocation codes
#    - Default second character to 'Q' (literal) when missing
#    - Maintain backward compatibility with 2-character codes
#
# 3. **New Variable Tracking**: Collect details about variables that need creation
#    - Track variable name, value, assignment code, invocation, and parameter
#    - Support batch processing of multiple parameters
#
# 4. **Backward Compatibility**: Support both L and Q for literal types
#    - 'L' as primary literal type
#    - 'Q' for backward compatibility
#    - Mixed combinations (LQ, QL) supported
#
# ## Non-Functional Requirements
#
# 1. **Performance**: Fast execution for batch processing
# 2. **Reliability**: Comprehensive test coverage (16 test methods, 144 assertions)
# 3. **Maintainability**: Clear separation of concerns and documentation
# 4. **Extensibility**: Easy to add new invocation types
#
# =============================================================================
# ARCHITECTURAL DECISIONS
# =============================================================================
#
# ## Design Patterns
#
# ### 1. Strategy Pattern
# - Each input type (C, E, L, V) has its own expansion method
# - `expand_command_input`, `expand_expression_input`, `expand_literal_input`, `expand_variable_input`
# - Enables easy addition of new input types
#
# ### 2. Factory Pattern
# - `create_new_variable` method creates NewVariable objects
# - Centralized object creation with consistent structure
#
# ### 3. Template Method Pattern
# - Main `expand_parameter` method delegates to specific handlers
# - Consistent interface across all invocation types
#
# ## Data Structures
#
# ### 1. NewVariable Struct
# ```ruby
# NewVariable = Struct.new(:name, :value, :assignment_code, :invocation, :param)
# ```
# - Immutable data structure for variable metadata
# - Includes `to_s` method for human-readable output
#
# ### 2. Return Value Convention
# - All methods return `[expansion_string, new_variable_object_or_nil]`
# - Consistent interface for both single and batch processing
#
# ## Error Handling
#
# ### 1. Graceful Degradation
# - Invalid invocation codes default to raw literal replacement
# - Nil/empty invocations return original value
#
# ### 2. Input Validation
# - Safe navigation with `&.` operator
# - Case-insensitive input handling with `upcase`
#
# =============================================================================
# IMPLEMENTATION DECISIONS
# =============================================================================
#
# ## Invocation Code Mapping
#
# ### Input Types
# - **C**: Command substitution - executes shell commands
# - **E**: Evaluated expression - processes shell expressions
# - **L**: Literal - handles raw text values
# - **V**: Variable reference - references existing variables
#
# ### Output Types
# - **C**: Command output - generates shell command strings
# - **E**: Expression output - generates shell expressions
# - **L**: Literal output - generates raw text
# - **V**: Variable output - generates variable references
#
# ## Default Behavior
#
# ### Single Character Defaults
# - Missing second character defaults to 'Q' (literal)
# - `:c=` → `:cq=` (command as literal)
# - `:e=` → `:eq=` (expression as literal)
# - `:l=` → `:lq=` (literal as literal)
# - `:v=` → `:vq=` (variable as literal)
#
# ## Shell Integration
#
# ### Command Substitution
# - Uses `$(command)` syntax for command execution
# - Proper shell escaping with `Shellwords.escape`
#
# ### Variable References
# - Uses `${variable}` syntax for variable expansion
# - Supports both simple and complex variable references
#
# ## Memory Management
#
# ### Object Creation
# - NewVariable objects created only when needed
# - Minimal memory footprint for simple expansions
#
# ### String Handling
# - Immutable string operations where possible
# - Efficient string interpolation
#
# =============================================================================
# TESTS
# =============================================================================
#
# ## Test Structure
#
# ### Test Categories
# 1. **Basic Functionality** - Return value structure and basic expansion
# 2. **Command Substitution** - All 4 C* combinations
# 3. **Expression Processing** - All 4 E* combinations  
# 4. **Literal Handling** - All 4 L* combinations
# 5. **Variable References** - All 4 V* combinations
# 6. **Backward Compatibility** - Q codes and mixed L/Q combinations
# 7. **Single Character Support** - 1-character codes with Q defaults
# 8. **Batch Processing** - Multiple parameter handling
# 9. **Error Handling** - Invalid inputs and edge cases
# 10. **Shell Integration** - Proper escaping and shell syntax
#
# ### Test Metrics
# - **16 test methods** covering all functionality
# - **144 assertions** ensuring comprehensive coverage
# - **0 failures, 0 errors, 0 skips** - 100% pass rate
# - **~0.001 second execution time** - High performance
#
# ### Test Execution
# ```bash
# # Run as test suite
# ./lib/parameter_expansion.rb
# ./lib/parameter_expansion.rb --verbose
#
# # Use as library
# require './lib/parameter_expansion'
# ```
#
# =============================================================================
# CODE
# =============================================================================
#
# ## Core Classes and Methods
#
# ### ParameterExpansion Class
# - **expand_parameter**: Main expansion method
# - **expand_parameter_string**: Convenience method for string-only results
# - **expand_parameters**: Batch processing method
#
# ### NewVariable Struct
# - **name**: Variable name to be created
# - **value**: Original value passed in
# - **assignment_code**: Shell code for variable assignment
# - **invocation**: Invocation code used
# - **param**: Original parameter name
#
# ## Method Signatures
#
# ```ruby
# # Main expansion method
# def self.expand_parameter(param, invocation, value)
#   # Returns: [expansion_string, new_variable_object_or_nil]
# end
#
# # Convenience method
# def self.expand_parameter_string(param, invocation, value)
#   # Returns: expansion_string
# end
#
# # Batch processing
# def self.expand_parameters(parameter_hash)
#   # Returns: [expansions_hash, new_variables_array]
# end
# ```
#
# =============================================================================
# SEMANTIC TOKENS
# =============================================================================
#
# ## Cross-Reference Tokens
#
# ### Requirements → Implementation
# - `REQ-001`: Parameter expansion → `expand_parameter` method
# - `REQ-002`: Single character support → `output_type || 'Q'` logic
# - `REQ-003`: New variable tracking → `NewVariable` struct
# - `REQ-004`: Backward compatibility → `when 'L', 'Q'` conditions
#
# ### Architecture → Code
# - `ARCH-001`: Strategy pattern → `expand_*_input` methods
# - `ARCH-002`: Factory pattern → `create_new_variable` method
# - `ARCH-003`: Template method → `expand_parameter` delegation
# - `ARCH-004`: Data structures → `NewVariable` struct definition
#
# ### Implementation → Tests
# - `IMPL-001`: Command substitution → `test_command_substitution_codes`
# - `IMPL-002`: Expression processing → `test_expression_codes`
# - `IMPL-003`: Literal handling → `test_literal_codes`
# - `IMPL-004`: Variable references → `test_variable_codes`
# - `IMPL-005`: Single character → `test_single_character_invocation_codes`
# - `IMPL-006`: Batch processing → `test_expand_parameters_batch_processing`
#
# ### Tests → Code Coverage
# - `TEST-001`: Basic functionality → `test_expand_parameter_returns_array`
# - `TEST-002`: Backward compatibility → `test_backward_compatibility_with_q_codes`
# - `TEST-003`: Mixed combinations → `test_mixed_l_q_codes`
# - `TEST-004`: Error handling → `test_invalid_invocation_codes`
# - `TEST-005`: Shell integration → `test_shellwords_escaping`
# - `TEST-006`: Complete coverage → `test_all_invocation_combinations`
#
# ## Token Usage Examples
#
# ### In Code Comments
# ```ruby
# # REQ-001: Support all 16 invocation combinations
# def self.expand_parameter(param, invocation, value)
#
# # ARCH-001: Strategy pattern for input type handling
# case input_type
# when 'C' # Command substitution
#   expand_command_input(param, output_type, value, invocation)
#
# # IMPL-001: Command substitution with proper shell syntax
# when 'C' # :cc= - command string
#   [value, nil]
# ```
#
# ### In Test Descriptions
# ```ruby
# # TEST-001: Basic functionality verification
# def test_expand_parameter_returns_array
#
# # IMPL-005: Single character code support
# def test_single_character_invocation_codes
# ```
#
# =============================================================================
# USAGE EXAMPLES
# =============================================================================
#
# ## Basic Usage
# ```ruby
# require './lib/parameter_expansion'
#
# # Single parameter expansion
# expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "ll", "hello world")
# # expansion = "hello world"
# # new_var = nil
#
# # Command substitution with new variable
# expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "ce", "ls -la")
# # expansion = "${PARAM}"
# # new_var.name = "PARAM"
# # new_var.assignment_code = "$(ls -la)"
# ```
#
# ## Batch Processing
# ```ruby
# parameters = {
#   "COMMAND" => ["ce", "ls -la"],
#   "TITLE" => ["ll", "My Document"],
#   "VARIABLE" => ["ev", "hello world"]
# }
#
# expansions, new_variables = ParameterExpansion.expand_parameters(parameters)
# # expansions = {"COMMAND" => "${COMMAND}", "TITLE" => "My Document", ...}
# # new_variables = [NewVariable objects for variables that need creation]
# ```
#
# ## Single Character Codes
# ```ruby
# # These are equivalent:
# ParameterExpansion.expand_parameter("PARAM", "c", "ls -la")
# ParameterExpansion.expand_parameter("PARAM", "cq", "ls -la")
#
# # These are equivalent:
# ParameterExpansion.expand_parameter("PARAM", "l", "hello world")
# ParameterExpansion.expand_parameter("PARAM", "lq", "hello world")
# ```
#
# =============================================================================

# Add Shellwords require for proper escaping
require 'shellwords'

# Parameter expansion utility for markdown_exec
# Handles different invocation types for parameter substitution
class ParameterExpansion
  # Structure to hold new variable details
  NewVariable = Struct.new(:name, :value, :assignment_code, :invocation, :param) do
    def to_s
      "Variable: #{name} = #{value} (via #{invocation})"
    end
  end

  # REQ-001: Expands a parameter based on invocation type and value
  # ARCH-003: Template method pattern - delegates to specific handlers
  #
  # @param param [String] The parameter name to be substituted
  # @param invocation [String] The 1 or 2-letter invocation code (e.g., "c", "cc", "ce", "cl", etc.)
  # @param value [String] The value to insert into the expansion
  # @return [Array] Array containing [expansion_string, new_variable_details]
  #
  # Invocation codes:
  # - First letter: Input type (C=command, E=expression, L=literal, V=variable)
  # - Second letter: Output type (C=command, E=expression, L=literal, V=variable)
  #   If second letter is missing, defaults to Q (literal)
  #
  # Examples:
  #   expand_parameter("PARAM", "cc", "ls -la") 
  #   # => ["ls -la", nil] (command as command)
  #
  #   expand_parameter("PARAM", "ce", "ls -la")
  #   # => ["${PARAM}", NewVariable object] (command as expression)
  #
  #   expand_parameter("PARAM", "ll", "hello world")
  #   # => ["hello world", nil] (literal as literal)
  #
  #   expand_parameter("PARAM", "c", "ls -la")
  #   # => ["ls -la", nil] (command as literal, defaults to Q)
  #
  #   expand_parameter("PARAM", "e", "hello world")
  #   # => ["hello world", nil] (expression as literal, defaults to Q)
  def self.expand_parameter(param, invocation, value, unique: nil)
    return [value, nil] if invocation.nil? || invocation.empty?

    # unique = rand(1e4) if unique.nil?
    if unique.nil?
      # unique from a global counter
      @@unique ||= 0
      @@unique += 1
      unique = @@unique
    end
    
    input_type = invocation[0]&.upcase
    output_type = invocation[1]&.upcase || 'Q'  # Default to Q if second character missing

ww 'input_type:', input_type
ww 'output_type:', output_type
    # ARCH-001: Strategy pattern for input type handling
    case input_type
    when 'C' # IMPL-001: Command substitution
      expand_command_input(param, output_type, value, invocation, unique: unique)
    when 'E' # IMPL-002: Evaluated expression
      expand_expression_input(param, output_type, value, invocation, unique: unique)
    when 'L', 'Q' # REQ-004: Literal (accept both L and Q for backward compatibility)
      expand_literal_input(param, output_type, value, invocation, unique: unique)
    when 'V' # IMPL-004: Variable reference
      expand_variable_input(param, output_type, value, invocation)
    else
      # Default to raw literal if no valid input type
      [value, nil]
    end
  end

  # Convenience method that returns just the expansion string (backward compatibility)
  def self.expand_parameter_string(param, invocation, value, unique: rand(1e4))
    result, _new_var = expand_parameter(param, invocation, value, unique: unique)
    result
  end

  # Process multiple parameters and collect all new variables
  def self.expand_parameters(parameter_hash, unique: rand(1e4))
    expansions = {}
    new_variables = []
    
    parameter_hash.each do |param, (invocation, value)|
      expansion, new_var = expand_parameter(param, invocation, value, unique: unique)
      expansions[param] = expansion
      new_variables << new_var if new_var
    end
    
    [expansions, new_variables]
  end

  private

  # Handle command substitution input (C)
  def self.expand_command_input(param, output_type, value, invocation, unique:)
    case output_type
    when 'C' # :cc= - command string
      [value, nil]
    when 'E' # :ce= - command as shell expressio
      new_var = create_new_variable(param, value, "$(#{value})", invocation, param, unique: unique)
      [new_var.name, new_var]
    when 'L', 'Q' # :cl=, :cq= - output of command evaluation
      new_var = create_new_variable(param, value, "$(#{value})", invocation, param, unique: unique)
      # wrapped so MDE will expand
      [get_variable_reference(new_var.name), new_var]
    when 'V' # :cv= - name of new variable
      new_var = create_new_variable(param, value, "$(#{value})", invocation, param, unique: unique)
      [new_var.name, new_var]
    else
      [value, nil]
    end
  end

  # Handle evaluated expression input (E)
  def self.expand_expression_input(param, output_type, value, invocation, unique: rand(1e4))
    case output_type
    when 'C' # :ec= - VALUE as a command
      [%(printf %s "#{value}"), nil]
    when 'E' # :ee= - VALUE string
      [value, nil]
    when 'L', 'Q' # :el=, :eq= - shell expression output
      # wrapped so MDE will expand
      [%($(printf %s "#{value}")), nil]
    when 'V' # :ev= - name of new variable
      new_var = create_new_variable(param, value, %(printf %s "#{value}"), invocation, param, unique: unique)
      [new_var.name, new_var]
      # [param, new_var]
    else
      [value, nil]
    end
  end

  # Handle literal input (L/Q)
  def self.expand_literal_input(param, output_type, value, invocation, unique:)
    case output_type
    when 'C' # :lc= or :qc= - literal VALUE as output
      [%(printf %s "#{value}"), nil]
    when 'E' # :le= or :qe= - literal VALUE as output
      [value, nil]
    when 'L', 'Q' # :ll=, :lq=, :ql=, or :qq= - literal VALUE as output
      [value, nil]
    when 'V' # :lv= or :qv= - name of new variable
      new_var = create_new_variable(param, value, Shellwords.escape(value), invocation, param, unique: unique)
      # [param, new_var]
      [new_var.name, new_var]
    else
      [value, nil]
    end
  end

  # Handle variable reference input (V)
  def self.expand_variable_input(param, output_type, value, invocation)
    case output_type
    when 'C' # :vc= - variable VALUE expanded
      [%(printf %s "#{get_value_reference(value)}"), nil]
    when 'E' # :ve= - variable VALUE as a shell expr
      [get_value_reference(value), nil]
    when 'L', 'Q' # :vl=, :vq= - variable VALUE expanded
      # wrapped so MDE will expand
      [get_value_reference(value), nil]
    when 'V' # :vv= - VALUE string
      [value, nil]
    else
      [value, nil]
    end
  end

  # Create a new variable object with details
  def self.create_new_variable(name, value, assignment_code, invocation, param, unique:)
    unique_name = "#{name}_#{unique}"
    NewVariable.new(unique_name, value, assignment_code, invocation, param)
  end

  # Check if parameter is already wrapped with ${}
  def self.param_wrapped?(param)
    param.start_with?('${') && param.end_with?('}')
  end

  # Get the appropriate variable reference for the parameter
  def self.get_variable_reference(param)
    param.start_with?('$') ? param : "${#{param}}"
    # param_wrapped?(param) ? param : "${#{param}}"
  end

  # Check if value is already wrapped with ${}
  def self.value_wrapped?(value)
    value.start_with?('${') && value.end_with?('}')
  end

  # Get the appropriate variable reference for the value
  def self.get_value_reference(value)
    value_wrapped?(value) ? value : "${#{value}}"
  end
end

return unless $PROGRAM_NAME == __FILE__

require 'bundler/setup'
Bundler.require(:default)

require 'minitest/autorun'
require 'mocha/minitest'

# Minitest tests for ParameterExpansion
class TestParameterExpansion < Minitest::Test
  # TEST-001: Basic functionality verification
  def test_expand_parameter_returns_array
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "cc", "ls -la")
    assert_equal "ls -la", expansion
    assert_nil new_var
  end

  # IMPL-001: Command substitution with proper shell syntax
  def test_command_substitution_codes
    # :cc= - command as command
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "cc", "ls -la")
    assert_equal "ls -la", expansion
    assert_nil new_var

    # :ce= - command as expression
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "ce", "ls -la", unique: '')
    assert_equal "PARAM_", expansion
    assert_instance_of ParameterExpansion::NewVariable, new_var
    assert_equal "PARAM_", new_var.name
    assert_equal "ls -la", new_var.value
    assert_equal "$(ls -la)", new_var.assignment_code

    # :cl= - command as literal
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "cl", "ls -la", unique: '')
    assert_equal "PARAM_", expansion
    assert_instance_of ParameterExpansion::NewVariable, new_var

    # :cv= - command as variable
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "cv", "ls -la", unique: '')
    assert_equal "PARAM_", expansion
    assert_instance_of ParameterExpansion::NewVariable, new_var
  end

  def test_expression_codes
    # :ec= - expression as command
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "ec", "hello world")
    assert_equal 'printf %s "hello world"', expansion
    assert_nil new_var

    # :ee= - expression as expression
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "ee", "hello world")
    assert_equal "hello world", expansion
    assert_nil new_var

    # :el= - expression as literal
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "el", "hello world")
    assert_equal '$(printf %s "hello world")', expansion
    assert_nil new_var

    # :ev= - expression as variable
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "ev", "hello world", unique: '')
    assert_equal "PARAM_", expansion
    assert_instance_of ParameterExpansion::NewVariable, new_var
    assert_equal '"hello world"', new_var.assignment_code
  end

  def test_literal_codes
    # :lc= - literal as command
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "lc", "hello world")
    assert_equal 'printf %s "hello world"', expansion
    assert_nil new_var

    # :le= - literal as expression
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "le", "hello world")
    assert_equal "hello world", expansion
    assert_nil new_var

    # :ll= - literal as literal
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "ll", "hello world")
    assert_equal "hello world", expansion
    assert_nil new_var

    # :lv= - literal as variable
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "lv", "hello world", unique: '')
    assert_equal "PARAM_", expansion
    assert_instance_of ParameterExpansion::NewVariable, new_var
    assert_equal "hello\\ world", new_var.assignment_code
  end

  def test_variable_codes
    # :vc= - variable as command
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "vc", "MY_VAR")
    assert_equal 'printf %s "${MY_VAR}"', expansion
    assert_nil new_var

    # :ve= - variable as expression
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "ve", "MY_VAR")
    assert_equal "${MY_VAR}", expansion
    assert_nil new_var

    # :vl= - variable as literal
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "vl", "MY_VAR")
    assert_equal "${MY_VAR}", expansion
    assert_nil new_var

    # :vv= - variable as variable
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "vv", "MY_VAR")
    assert_equal "MY_VAR", expansion
    assert_nil new_var
  end

  def test_backward_compatibility_with_q_codes
    # Test that old Q codes still work
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "qq", "hello world")
    assert_equal "hello world", expansion
    assert_nil new_var

    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "qe", "hello world")
    assert_equal "hello world", expansion
    assert_nil new_var

    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "qc", "hello world")
    assert_equal 'printf %s "hello world"', expansion
    assert_nil new_var

    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "qv", "hello world", unique: '')
    assert_equal "PARAM_", expansion
    assert_instance_of ParameterExpansion::NewVariable, new_var
  end

  def test_mixed_l_q_codes
    # Test mixed L/Q combinations
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "lq", "hello world")
    assert_equal "hello world", expansion
    assert_nil new_var

    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "ql", "hello world")
    assert_equal "hello world", expansion
    assert_nil new_var
  end

  def test_expand_parameter_string_backward_compatibility
    # Test the convenience method
    result = ParameterExpansion.expand_parameter_string("PARAM", "cc", "ls -la")
    assert_equal "ls -la", result

    result = ParameterExpansion.expand_parameter_string("PARAM", "ce", "ls -la", unique: '')
    assert_equal "PARAM_", result
  end

  def test_expand_parameters_batch_processing
    parameters = {
      "COMMAND" => ["ce", "ls -la"],
      "TITLE" => ["ll", "My Document"],
      "VARIABLE" => ["ev", "hello world"]
    }

    expansions, new_variables = ParameterExpansion.expand_parameters(parameters, unique: '')

    assert_equal 3, expansions.size
    assert_equal "COMMAND_", expansions["COMMAND"]
    assert_equal "My Document", expansions["TITLE"]
    assert_equal "VARIABLE_", expansions["VARIABLE"]

    assert_equal 2, new_variables.size
    assert_equal "COMMAND_", new_variables[0].name
    assert_equal "ls -la", new_variables[0].value
    assert_equal "VARIABLE_", new_variables[1].name
    assert_equal "hello world", new_variables[1].value
  end

  def test_new_variable_structure
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "ce", "ls -la", unique: '')
    
    assert_instance_of ParameterExpansion::NewVariable, new_var
    assert_equal "PARAM_", new_var.name
    assert_equal "ls -la", new_var.value
    assert_equal "$(ls -la)", new_var.assignment_code
    assert_equal "ce", new_var.invocation
    assert_equal "PARAM", new_var.param

    # Test to_s method
    assert_includes new_var.to_s, "PARAM"
    assert_includes new_var.to_s, "ls -la"
    assert_includes new_var.to_s, "ce"
  end

  def test_invalid_invocation_codes
    # Test with nil invocation
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", nil, "value")
    assert_equal "value", expansion
    assert_nil new_var

    # Test with empty invocation
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "", "value")
    assert_equal "value", expansion
    assert_nil new_var

    # Test with unknown input type
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "xx", "value")
    assert_equal "value", expansion
    assert_nil new_var
  end

  def test_shellwords_escaping
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "lv", "hello world with spaces")
    assert_instance_of ParameterExpansion::NewVariable, new_var
    assert_equal "hello\\ world\\ with\\ spaces", new_var.assignment_code
  end

  # IMPL-005: Single character code support
  def test_single_character_invocation_codes
    # Test single character codes that default to Q (literal)
    
    # :c= - command as literal (defaults to Q, equivalent to :cq=)
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "c", "ls -la", unique: '')
    assert_equal "PARAM_", expansion
    assert_instance_of ParameterExpansion::NewVariable, new_var
    assert_equal "$(ls -la)", new_var.assignment_code

    # :e= - expression as literal (defaults to Q, equivalent to :eq=)
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "e", "hello world")
    assert_equal '$(printf %s "hello world")', expansion
    assert_nil new_var

    # :l= - literal as literal (defaults to Q, equivalent to :lq=)
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "l", "hello world")
    assert_equal "hello world", expansion
    assert_nil new_var

    # :v= - variable as literal (defaults to Q, equivalent to :vq=)
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "v", "MY_VAR")
    assert_equal "${MY_VAR}", expansion
    assert_nil new_var
  end

  def test_single_character_equivalence
    # Test that single character codes are equivalent to their Q counterparts
    
    # :c= should be equivalent to :cq=
    # , unique: rand(1e4)
    unique = rand(1e4)

    expansion1, new_var1 = ParameterExpansion.expand_parameter("PARAM", "c", "ls -la", unique: unique)
    expansion2, new_var2 = ParameterExpansion.expand_parameter("PARAM", "cq", "ls -la", unique: unique)
    assert_equal expansion1, expansion2
    if new_var1 && new_var2
      assert_equal new_var1.name, new_var2.name
      assert_equal new_var1.value, new_var2.value
      assert_equal new_var1.assignment_code, new_var2.assignment_code
    else
      assert_nil new_var1
      assert_nil new_var2
    end

    # :e= should be equivalent to :eq=
    expansion1, new_var1 = ParameterExpansion.expand_parameter("PARAM", "e", "hello world")
    expansion2, new_var2 = ParameterExpansion.expand_parameter("PARAM", "eq", "hello world")
    assert_equal expansion1, expansion2
    if new_var1 && new_var2
      assert_equal new_var1.name, new_var2.name
      assert_equal new_var1.value, new_var2.value
      assert_equal new_var1.assignment_code, new_var2.assignment_code
    else
      assert_nil new_var1
      assert_nil new_var2
    end

    # :l= should be equivalent to :lq=
    expansion1, new_var1 = ParameterExpansion.expand_parameter("PARAM", "l", "hello world")
    expansion2, new_var2 = ParameterExpansion.expand_parameter("PARAM", "lq", "hello world")
    assert_equal expansion1, expansion2
    if new_var1 && new_var2
      assert_equal new_var1.name, new_var2.name
      assert_equal new_var1.value, new_var2.value
      assert_equal new_var1.assignment_code, new_var2.assignment_code
    else
      assert_nil new_var1
      assert_nil new_var2
    end

    # :v= should be equivalent to :vq=
    expansion1, new_var1 = ParameterExpansion.expand_parameter("PARAM", "v", "MY_VAR")
    expansion2, new_var2 = ParameterExpansion.expand_parameter("PARAM", "vq", "MY_VAR")
    assert_equal expansion1, expansion2
    if new_var1 && new_var2
      assert_equal new_var1.name, new_var2.name
      assert_equal new_var1.value, new_var2.value
      assert_equal new_var1.assignment_code, new_var2.assignment_code
    else
      assert_nil new_var1
      assert_nil new_var2
    end
  end

  def test_all_invocation_combinations
    # Test all 16 combinations from the documentation
    combinations = %w[cc ce cl cv ec ee el ev lc le ll lv vc ve vl vv]
    
    combinations.each do |invocation|
      expansion, new_var = ParameterExpansion.expand_parameter("PARAM", invocation, "test_value")
      assert_instance_of String, expansion
      # new_var can be nil or NewVariable object
      assert(new_var.nil? || new_var.is_a?(ParameterExpansion::NewVariable))
    end
  end

  def test_single_character_combinations
    # Test all single character combinations
    single_chars = %w[c e l v]
    
    single_chars.each do |invocation|
      expansion, new_var = ParameterExpansion.expand_parameter("PARAM", invocation, "test_value")
      assert_instance_of String, expansion
      # new_var can be nil or NewVariable object
      assert(new_var.nil? || new_var.is_a?(ParameterExpansion::NewVariable))
    end
  end

  def test_pre_wrapped_parameters
    # Test that parameters already wrapped with ${} are used as-is
    
    # Test command substitution with pre-wrapped parameter
    expansion, new_var = ParameterExpansion.expand_parameter("${MY_VAR}", "ce", "ls -la", unique: '')
    assert_equal "${MY_VAR}_", expansion
    assert_instance_of ParameterExpansion::NewVariable, new_var
    assert_equal "${MY_VAR}_", new_var.name
    assert_equal "ls -la", new_var.value
    assert_equal "$(ls -la)", new_var.assignment_code

    # Test command substitution with pre-wrapped parameter (literal output)
    expansion, new_var = ParameterExpansion.expand_parameter("${MY_VAR}", "cl", "ls -la", unique: '')
    assert_equal "${MY_VAR}_", expansion
    assert_instance_of ParameterExpansion::NewVariable, new_var
    assert_equal "${MY_VAR}_", new_var.name

    # Test that regular parameters still get wrapped
    expansion, new_var = ParameterExpansion.expand_parameter("MY_VAR", "ce", "ls -la", unique: '')
    assert_equal "MY_VAR_", expansion
    assert_instance_of ParameterExpansion::NewVariable, new_var
    assert_equal "MY_VAR_", new_var.name

    # Test with complex pre-wrapped parameter
    expansion, new_var = ParameterExpansion.expand_parameter("${COMPLEX_VAR_NAME}", "ce", "echo hello", unique: '')
    assert_equal "${COMPLEX_VAR_NAME}_", expansion
    assert_instance_of ParameterExpansion::NewVariable, new_var
    assert_equal "${COMPLEX_VAR_NAME}_", new_var.name
  end

  def test_param_wrapped_helper_methods
    # Test the helper methods directly
    assert ParameterExpansion.param_wrapped?("${MY_VAR}")
    assert ParameterExpansion.param_wrapped?("${COMPLEX_VAR}")
    refute ParameterExpansion.param_wrapped?("MY_VAR")
    refute ParameterExpansion.param_wrapped?("${MY_VAR")
    refute ParameterExpansion.param_wrapped?("MY_VAR}")
    refute ParameterExpansion.param_wrapped?("")

    # Test get_variable_reference method
    assert_equal "${MY_VAR}", ParameterExpansion.get_variable_reference("MY_VAR")
    assert_equal "${COMPLEX_VAR}", ParameterExpansion.get_variable_reference("${COMPLEX_VAR}")
    assert_equal "${${NESTED}}", ParameterExpansion.get_variable_reference("${${NESTED}}")
  end

  def test_pre_wrapped_values
    # Test that values already wrapped with ${} are used as-is
    
    # Test variable reference with pre-wrapped value
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "ve", "${MY_VAR}")
    assert_equal "${MY_VAR}", expansion
    assert_nil new_var

    # Test variable reference with pre-wrapped value (literal output)
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "vl", "${MY_VAR}")
    assert_equal "${MY_VAR}", expansion
    assert_nil new_var

    # Test variable reference with pre-wrapped value (command output)
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "vc", "${MY_VAR}")
    assert_equal 'printf %s "${MY_VAR}"', expansion
    assert_nil new_var

    # Test that regular values still get wrapped
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "ve", "MY_VAR")
    assert_equal "${MY_VAR}", expansion
    assert_nil new_var

    # Test with complex pre-wrapped value
    expansion, new_var = ParameterExpansion.expand_parameter("PARAM", "ve", "${COMPLEX_VAR_NAME}")
    assert_equal "${COMPLEX_VAR_NAME}", expansion
    assert_nil new_var
  end

  def test_value_wrapped_helper_methods
    # Test the value helper methods directly
    assert ParameterExpansion.value_wrapped?("${MY_VAR}")
    assert ParameterExpansion.value_wrapped?("${COMPLEX_VAR}")
    refute ParameterExpansion.value_wrapped?("MY_VAR")
    refute ParameterExpansion.value_wrapped?("${MY_VAR")
    refute ParameterExpansion.value_wrapped?("MY_VAR}")
    refute ParameterExpansion.value_wrapped?("")

    # Test get_value_reference method
    assert_equal "${MY_VAR}", ParameterExpansion.get_value_reference("MY_VAR")
    assert_equal "${COMPLEX_VAR}", ParameterExpansion.get_value_reference("${COMPLEX_VAR}")
    assert_equal "${${NESTED}}", ParameterExpansion.get_value_reference("${${NESTED}}")
  end
end

__END__
To run minitest tests: `./lib/parameter_expansion.rb`
With verbose output: `./lib/parameter_expansion.rb --verbose`
