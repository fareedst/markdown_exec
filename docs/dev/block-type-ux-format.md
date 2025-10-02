/ v2025-06-28
/ Demonstrate using a format key does not inhibit activation of the same block
/
```ux
act: :echo
echo: '`date`'
format: 'Date: ${DATE}'
name: DATE
```
@import bats-document-configuration.md