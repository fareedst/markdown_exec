``` :(hidden)
```
``` :visible
```
/ ux block is displayed differently than other types
```ux :()
name: name
```
@import bats-document-configuration.md
```opts :(document_opts)
# Pattern for blocks to hide from user-selection
block_name_hidden_match:
  ^\(.*\)$

# Pattern for the block name in the line defining the block
block_name_match: |
  :(?<title>\S+)( |$)
```