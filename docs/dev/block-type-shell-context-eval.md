```vars :(document_vars)
VARS1: '0.0'
```
/ these lines are appended to the context; print values
```bash :[context] +print-values @context
SHELL_V1="${VARS1}, 1.1"
SHELL_V2="${VARS1}, 1.2"
```

/ these lines are executed and the output is the transient code; print values
```bash :[eval] +print-values @eval
echo "SHELL_V1=\"${VARS1}, 2.1\""
echo "SHELL_V2=\"${VARS1}, 2.2\""
```

/ these lines are executed and the output is appended to the context; print values
```bash :[eval-context] +print-values @eval @context
echo "SHELL_V1=\"${VARS1}, 3.1\""
echo "SHELL_V2=\"${VARS1}, 3.2\""
```

/ require block setting context; set transient code; print values
```bash :[require-context] +[context]
SHELL_V1="${SHELL_V1}, 4.1"
SHELL_V2="${SHELL_V2}, 4.2"
```

/ require block setting context from eval output; set transient code; print values
```bash :[require-eval-context] +[eval-context]
SHELL_V1="${SHELL_V1}, 5.1"
SHELL_V2="${SHELL_V2}, 5.2"
```

/ these values are present while the block is being evaluated
```bash :print-values 
echo "~ SHELL_V1=$SHELL_V1"
echo "~ SHELL_V2=$SHELL_V2"
```
```opts :[opts]
dump_context_code: true
```
/| Variable| Value
/| -| -
/| VARS1| ${VARS1}
/| SHELL_V1| ${SHELL_V1}
/| SHELL_V2| ${SHELL_V2}
@import bats-document-configuration.md
```opts :(document_opts)
/dump_context_code: true
/menu_for_saved_lines: true
menu_with_exit: true
```