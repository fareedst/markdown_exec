#!/usr/bin/env bats

greet () {
  echo "Hello, $1"'!'
  sleep 9
}

@test 'Export function, variables to BATS; exit a running job' {
  name='World'
  export name
  export -f greet
  run bash -c "
    greet \"$(echo '$name')\" &"'
    pid="$!"

    # Wait for 1 second, to show it is not stopping
    sleep 1

    if kill -0 $pid 2>/dev/null; then
      kill $pid
      wait $pid 2>/dev/null
      exit_status=$?
    else
      wait $pid 2>/dev/null
      exit_status=$?
    fi
    echo -n "$exit_status" > /tmp/exit_status
  '
  # app exits with an error code
  [ "$(cat /tmp/exit_status)" = 143 ]
  [ "$status" = 0 ]
  [ "$output" = "Hello, World!" ]
}
