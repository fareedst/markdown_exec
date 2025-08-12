```bash :(document_shell)
##
# hexdump_format
#
# Produce a per-byte hex dump of a string in two-line blocks:
#  • First line shows up to sixteen characters.
#  • Second line shows the corresponding hex values.
# An optional LABEL is prepended on the first line, and the second
# line is padded to align its colon under the first.
# Uses only Bash built-ins.
#
# Usage:
#   hexdump_format [STRING] [--label LABEL] [--width BYTES] [--offset-width DIGITS] [--start-offset OFFSET] [--end-offset OFFSET] [--character-ansi COLOR] [--hex-ansi COLOR] [--offset-ansi COLOR] [--help]
#   Options:
#     STRING                The string to dump (optional first positional argument)
#     --label LABEL         Optional label to display
#     --width BYTES         Number of bytes per line (default: 16)
#     --offset-width DIGITS Number of digits in offset display
#     --start-offset OFFSET Start offset into the string (default: 0)
#     --end-offset OFFSET   End offset into the string (default: string length)
#     --character-ansi COLOR ANSI color code for character display (default: 35)
#     --hex-ansi COLOR      ANSI color code for hex display (default: 36)
#     --offset-ansi COLOR   ANSI color code for offset display (default: 33)
#     --help               Show this help message
##
hexdump_format () {
  # Default values
  local data=""
  local label=""
  local width="16"
  local offset_width=""
  local start_offset="0"
  local end_offset=""
  local char_ansi_color="35"  # Default character color (magenta)
  local hex_ansi_color="36"   # Default hex color (cyan)
  local offset_ansi_color="33" # Default offset color (yellow)

  # Show help if no arguments provided
  if [[ $# -eq 0 ]]; then
    echo "Usage: hexdump_format [STRING] [OPTIONS]"
    echo
    echo "Display a hex dump of a string with optional formatting."
    echo
    echo "Arguments:"
    echo "  STRING                The string to dump (optional first positional argument)"
    echo
    echo "Options:"
    echo "  --data DATA           The string to dump"
    echo "  --label LABEL         Optional label to display"
    echo "  --width BYTES         Number of bytes per line (default: 16)"
    echo "  --offset-width DIGITS Number of digits in offset display"
    echo "  --start-offset OFFSET Start offset into the string (default: 0)"
    echo "  --end-offset OFFSET   End offset into the string (default: string length)"
    echo "  --character-ansi COLOR ANSI color code for character display (default: 35)"
    echo "  --hex-ansi COLOR      ANSI color code for hex display (default: 36)"
    echo "  --offset-ansi COLOR   ANSI color code for offset display (default: 33)"
    echo "  --help               Show this help message"
    echo
    echo "Examples:"
    echo "  hexdump_format \"Hello World\""
    echo "  hexdump_format --data \"Hello World\" --width 8"
    echo "  hexdump_format \"Hello World\" --character-ansi 32 --hex-ansi 31"
    return 0
  fi

  # Check if first argument is --help
  if [[ "$1" == "--help" ]]; then
    hexdump_format
    return 0
  fi

  # Check if first argument is not an option (starts with --)
  if [[ "$1" != --* ]]; then
    data="$1"
    shift
  fi

  # Process all options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --data)
        if [[ -z "$2" ]]; then
          echo "Error: --data requires a value" >&2
          return 1
        fi
        data="$2"
        shift 2
        ;;
      --label)
        if [[ -z "$2" ]]; then
          echo "Error: --label requires a value" >&2
          return 1
        fi
        label="$2 "
        shift 2
        ;;
      --width)
        if [[ -z "$2" ]]; then
          echo "Error: --width requires a value" >&2
          return 1
        fi
        width="$2"
        shift 2
        ;;
      --offset-width)
        if [[ -z "$2" ]]; then
          echo "Error: --offset-width requires a value" >&2
          return 1
        fi
        offset_width="$2"
        shift 2
        ;;
      --start-offset)
        if [[ -z "$2" ]]; then
          echo "Error: --start-offset requires a value" >&2
          return 1
        fi
        start_offset="$2"
        shift 2
        ;;
      --end-offset)
        if [[ -z "$2" ]]; then
          echo "Error: --end-offset requires a value" >&2
          return 1
        fi
        end_offset="$2"
        shift 2
        ;;
      --character-ansi)
        if [[ -z "$2" ]]; then
          echo "Error: --character-ansi requires a value" >&2
          return 1
        fi
        char_ansi_color="$2"
        shift 2
        ;;
      --hex-ansi)
        if [[ -z "$2" ]]; then
          echo "Error: --hex-ansi requires a value" >&2
          return 1
        fi
        hex_ansi_color="$2"
        shift 2
        ;;
      --offset-ansi)
        if [[ -z "$2" ]]; then
          echo "Error: --offset-ansi requires a value" >&2
          return 1
        fi
        offset_ansi_color="$2"
        shift 2
        ;;
      --help)
        hexdump_format
        return 0
        ;;
      *)
        echo "Error: Unknown option: $1" >&2
        return 1
        ;;
    esac
  done

  # Validate required parameters
  if [[ -z "$data" ]]; then
    echo "Error: No data provided. Use --data or provide a string as the first argument." >&2
    echo "Use --help for usage information." >&2
    return 1
  fi

  # Set end_offset to string length if not provided
  if [[ -z "$end_offset" ]]; then
    end_offset="${#data}"
  fi

  local len=${#data}
  local -i idx=0
  local esc=$'\e'
  local char_color="${esc}[${char_ansi_color}m"
  local hex_color="${esc}[${hex_ansi_color}m"
  local offset_color="${esc}[${offset_ansi_color}m"
  local reset="${esc}[0m"

  # Convert offsets to decimal integers
  if [[ $start_offset =~ ^0[xX][0-9a-fA-F]+$ ]]; then
    # Convert hex to decimal - strip 0x prefix first
    start_offset=$((16#${start_offset#0x}))
  elif [[ $start_offset =~ ^0[0-7]+$ ]]; then
    # Convert octal to decimal
    start_offset=$((8#$start_offset))
  fi

  if [[ $end_offset =~ ^0[xX][0-9a-fA-F]+$ ]]; then
    # Convert hex to decimal - strip 0x prefix first
    end_offset=$((16#${end_offset#0x}))
  elif [[ $end_offset =~ ^0[0-7]+$ ]]; then
    # Convert octal to decimal
    end_offset=$((8#$end_offset))
  fi

  # Calculate actual start and end positions
  if (( start_offset < 0 )); then
    start_offset=$((len + start_offset))
  fi
  if (( end_offset < 0 )); then
    end_offset=$((len + end_offset))
  fi

  # Validate and adjust offsets
  start_offset=$((start_offset < 0 ? 0 : start_offset))
  end_offset=$((end_offset > len ? len : end_offset))
  if (( start_offset >= end_offset )); then
    return 0
  fi

  # Adjust data to start from the correct offset
  data="${data:start_offset:end_offset-start_offset}"
  len=${#data}

  while (( idx < len )); do
    local chars=() hexs=()

    # collect up to width bytes
    for (( j=0; j<$width && idx<len; j++, idx++ )); do
      local ch="${data:idx:1}"
      local ord
      printf -v ord '%d' "'$ch"
      chars+=( "$ch" )
      hexs+=( "$(printf '%02X' "$ord")" )
    done

    # first line: label only on the very first block
    if (( idx <= j )); then
      printf '%s' "$label"
    else
      printf '%*s' "${#label}" ""
    fi

    # print offset if width is specified
    if [[ -n "$offset_width" ]]; then
      printf '%b%0*x:%b ' "$offset_color" "$offset_width" $((start_offset + idx-j)) "$reset"
    fi

    # print characters, two spaces between each
    printf ' %b%s' "$char_color" "${chars[0]}"
    for (( k=1; k<${#chars[@]}; k++ )); do
      printf '  %s' "${chars[k]}"
    done
    printf '%s\n' "$reset"

    # second line: pad to align colon under first line
    printf '%*s' "${#label}" ""

    # print offset padding if width is specified
    if [[ -n "$offset_width" ]]; then
      printf '%*s' $((offset_width + 2)) "" # +2 for the colon and space
    fi

    # print hex values, single space between each
    printf '%b%s' "$hex_color" "${hexs[0]}"
    for (( k=1; k<${#hexs[@]}; k++ )); do
      printf ' %s' "${hexs[k]}"
    done
    printf '%s\n' "$reset"
  done
}
```