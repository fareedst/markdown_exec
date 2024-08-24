# repnew
#
# A function to process a string by removing ANSI escape sequences and replacing
# newlines with spaces. This is particularly useful when dealing with formatted
# text output that includes color codes or other terminal formatting and needs
# to be sanitized for plain text processing.
#
# Parameters:
#   $1 (string): The input string that may contain ANSI escape sequences and/or
#                newlines.
#
# Returns:
#   The processed string with ANSI escape sequences removed and newlines replaced
#   by spaces.
#
# Example:
#   input="Hello \e[31mWorld\e[0m\nThis is a test."
#   result=$(repnew "$input")
#   echo "$result"
#   # Output: "Hello World This is a test."
#
# Note:
#   - The function does not modify the original input string but returns a new
#     processed string.
#   - ANSI escape sequences are sequences used to control formatting, color, and
#     other output options on text terminals.
#
repnew () {
  printf '%s' "$1" | sed -E 's/\x1b\[[0-9;]*[a-zA-Z]//g' | tr '\n' ' '
}

expect_equal_output () {
  [[ "$1" == $(repnew "$2") ]]
}

exec_mde () {
  echo "bin/bmde "$1" "${@:2}""
  run bin/bmde "$1" ${@:2}
}

specs_md () {
  expect="${!#}"
  exec_mde docs/dev/specs.md ${@:1:$#-1}

  if ( ! expect_equal_output "$expect" "$output" ); then
    echo -e "- command: ${@:1:$#-1}"
    echo -e "- expected:\n$expect"
    echo -e "- output:\n$(repnew "$output")"
    echo "$output" | hexdump -C
  fi
  expect_equal_output "$expect" "$output"
  (( $status != $0 )) && echo "s:$status"
  [ "$status" -eq 0 ]
}

spec_mde_args_expect () {
  _args="$1"
  _expect="$2"
  run bin/bmde $_args

  if ( ! expect_equal_output "$_expect" "$output" ); then
    echo -e "- args: $_args"
    echo -e "- expected:\n$_expect"
    echo -e "- output:\n$(repnew "$output")"
    echo "$output" | hexdump -C
  fi
  expect_equal_output "$_expect" "$output"
  (( $status != $0 )) && echo "s:$status"
  [ "$status" -eq 0 ]
}

spec_mde_args_expect_g () {
  spec_mde_args_expect "$args" "$expect"
}
