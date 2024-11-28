# facilitate execution of program, comparison of output

date_from_history_file_name () {
  basename "$1" | sed -E 's/.*([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/'
}

echo_hexdump () {
  echo -en "$1" | hexdump -C
}

echo_hexdump_expected_output_filter () {
  local expected="$1"
  local output="$2"
  local filter="$3"

  echo -e "- output_$(echo "$output" | wc -l)_$(echo -n "$output" | wc -c):\n$output"
  if [[ $filter == A ]]; then
    echo -e "- converted_$(echo "$output" | wc -l)_$(echo -n "$output" | wc -c):"
    echo "$(remove_ansi_escape_sequences "$output")"
  fi
  echo -e "- expected_$(echo "$expected" | wc -l)_$(echo -n "$expected" | wc -c):\n$expected"

  if [[ $filter == A ]]; then
    echo "- output"
    echo_hexdump "$output"
    echo "- converted"
    echo_hexdump "$(remove_ansi_escape_sequences "$output")"
    echo "- expected"
    echo_hexdump "$expected"
  fi
} 

echo_xansi_command_expected_output_filter () {
  local command="$1"
  local expected="$2"
  local output="$3"
  local filter="$4"

  echo -e "- command: $command"
  echo -e "- expected:\n$expected"
  echo_hexdump "$expected"
  echo -e "- output:\n$(text_filter_ansi "$output" "$filter")"
  echo_hexdump "$output"
}

exec_mde () {
  echo "bin/bmde "$1" "${@:2}""
  run bin/bmde "$1" ${@:2}
}

expect_equal_with_conversion () {
  local expected="$1"
  local actual="$2"
  if [[ $3 == A ]]; then
    actual="$(remove_ansi_escape_sequences "$2")"
    if [[ -n $EXPECT_VERBOSE ]]; then
      echo "- expected"
      echo "$expected" | hexdump -C
      echo "- actual"
      echo "$actual" | hexdump -C
    fi
  fi
  [[ "$expected" == "$actual" ]]
}

hex_dump () {
  local separator=" --- "
  local output=""
  
  echo -en "$@" >&2
  for arg in "$@"; do
    output+="${arg}${separator}"
  done
  
  output="${output%$separator}"  # Remove the trailing separator
  echo "output: $output"
  echo ":"
  echo -en "$output" | hexdump -C >&2
}

most_recent_history_file_name () {
  ls -f logs/*examples_save_md* | tail -n 1
}

# remove_ansi_escape_sequences
#
# A function to process a string by removing ANSI escape sequences and replacing
# newlines with spaces. This is particularly useful when dealing with formatted
# text output that includes color codes or other terminal formatting and needs
# to be sanitized for plain text processing.
#
# Parameters:
#   $1 (string): The input string that may contain ANSI escape sequences and/or
#                various whitespace characters (newlines, tabs, etc.).
#
# Returns:
#   The processed string with ANSI escape sequences removed and all specified
#   whitespace characters replaced by spaces.
#
# Example:
#   input="Hello \e[31mWorld\e[0m\nThis\tis\ra test.\vPage\fBreak"
#   result=$(remove_ansi_escape_sequences "$input")
#   echo "$result"
#   # Output: "Hello World This is a test. Page Break"
#
# Note:
#   - The function does not modify the original input string but returns a new
#     processed string.
#   - ANSI escape sequences are sequences used to control formatting, color, and
#     other output options on text terminals.
#   - The following whitespace characters are replaced with spaces: newlines (\n),
#     tabs (\t), carriage returns (\r), vertical tabs (\v), and form feeds (\f).
#
remove_ansi_escape_sequences() {
  echo -en "$1" | perl -pe 's/\e\[\?*[0-9;]*[a-zA-Z]//g' | tr '\n\t\r\v\f' "${BATS_SAFE:- }"
}

run_mde_specs_md_args_expect_xansi () {
  expected="${!#}"
  exec_mde docs/dev/specs.md ${@:1:$#-1}

  filter="${BATS_OUTPUT_FILTER:-A}"
  if ( ! expect_equal_with_conversion "$expected" "$output" "$filter" ); then
    echo_xansi_command_expected_output_filter "${@:1:$#-1}" "$expected" "$output" "$filter"
  fi

  expect_equal_with_conversion "$expected" "$output" "$filter"
  (( $status != 0 )) && echo "- status: $status"
  [ "$status" -eq 0 ]
}

silence_ww () {
  unset WW
  "$@"
}

spec_mde_args_expect () {
  # while :; do
  #   SHIFT_COUNT=2
  #   case "$1" in
  #     --ansver)   RANSVER="$2"   ;;
  #     --auto)     TTY=""        ; SHIFT_COUNT=1 ;;
  #     *) break ;;
  #   esac
  #   shift "$SHIFT_COUNT"
  # done
  # spec_mde_args_grep_filter_expect ${@:1:$#-1} "$BATS_OUTPUT_GREP" "$BATS_OUTPUT_FILTER" "${@: -1}"

  # Use an array to handle the words
  # IFS=' ' read -r -a args <<< "$@"

  args=()
  for arg in "$@"; do
    if [[ $arg =~ ^\"(.*)\"$ ]]; then
      # Handle fully quoted string (preserves spaces inside quotes)
      args+=("${BASH_REMATCH[1]}")
    else
      # Non-quoted or partially quoted strings (preserves as-is)
      args+=("$arg")
    fi
  done

  spec_mde_args_grep_filter_expect \
   "${args[@]:0:${#args[@]}-1}" \
   "$BATS_OUTPUT_GREP" \
   "$BATS_OUTPUT_FILTER" \
   "${args[@]: -1}"
}

spec_mde_args_grep_filter_expect () {
  # Capturing arguments
  local remaining=("${@:1:$(($#-3))}")
  local pattern="${@: -3:1}"
  local filter="${@: -2:1}"
  local expected="${@: -1}"
  local STATUS="${BATS_STATUS:-0}"
  local EXE="${BATS_EXE:-bin/bmde}"
  SL="${BATS_SLEEP}"

  if [[ -z $SL ]]; then
    echo >&2 $EXE "${remaining[@]}"

    # Pass the exact arguments including empty and space-containing ones
    run $EXE "${remaining[@]}"
  else
    bash -c "
      SL=$SL
      bin/bmde ${remaining[@]} >/tmp/mde.out &"'
      app_pid=$!
      sleep $SL
      kill $app_pid && wait $app_pid 2>/dev/null
      ls -al /tmp/mde.out
      # cat /tmp/mde.out
      :'
    output="$(cat /tmp/mde.out)"
    rm /tmp/mde.out
  fi
  local output0="$output"
  if [[ -n $pattern ]]; then
    # prevent error from grep
    output="$(echo -en "$output" | grep "$pattern")" || :
  fi

  if ( ! expect_equal_with_conversion "$expected" "$output" "$filter"); then
    echo_hexdump_expected_output_filter "$expected" "$output" "$filter"
  fi
  expect_equal_with_conversion "$expected" "$output" "$filter"
  [[ -n $status ]] && echo "- status: $status"
  [[ -n $status ]]
}

spec_mde_xansi_dname_doc_blocks_expect () {
  BATS_OUTPUT_FILTER=A
  BATS_SAFE=_
  spec_mde_args_expect "$1" \
   "${@:2:$(($#-2))}" \
   --list-blocks-message dname \
   --list-blocks-type 3 \
   --list-blocks \
  "${!#}"
}

spec_mde_xansi_oname_doc_blocks_expect () {
  BATS_OUTPUT_FILTER=A
  BATS_SAFE=_
  spec_mde_args_expect "$1" \
   "${@:2:$(($#-2))}" \
   --list-blocks-message oname \
   --list-blocks-type 3 \
   --list-blocks \
  "${!#}"
}

text_filter_ansi () {
  if [[ $# -eq 2 ]]; then
    remove_ansi_escape_sequences "$1"
  else
    echo -n "$1"
  fi
}
