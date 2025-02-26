/ Retain whitespace in output from shell blocks
``` :[make-output]
echo 'Species'
echo -e " Genus\n  Family\tOrder"
```
@import bats-document-configuration.md
```opts :(document_opts)
line_decor_pre:
  - :color_method: :ansi_38_2_200_200_33__48_2_60_60_32__0
    :pattern: '%([^_]{0,64})%'
```