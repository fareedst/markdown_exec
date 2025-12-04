```link :[link-file-block-with-vars]
block: echo-ARG1
file: docs/dev/linked-file.md
vars:
  ARG1: arg1-from-link-file
```
```link :[link-local-block-with-vars]
block: output_arguments
vars:
  ARG1: 37
```
```link :[link-missing-local-block]
block: missing
```
```bash :[set-env] +output_arguments
ARG1=37
```
```bash :output_arguments
echo "ARG1: $ARG1"
```
@import bats-document-configuration.md
```opts :(document_opts)
menu_with_exit: true
menu_with_context_code: true
```