/ assign a multiline string
```vars :(document_vars)
Genus2: |
  Pongo
  Pongo
```
/
/ display the variable
__UX block__:
```ux
name: Genus2
readonly: true
```
/
/ Confirm the string contains a newline `0a`
__Command substitution__:
Genus2 hex: $(printf "$Genus2" | hexdump -v -e '16/1 " %02x"')
/
/ output with substitution
__Command substitution__:
Genus2 text: $(printf "$Genus2")
/
/ output with substitution
__Command substitution__:
$(ls -1 G*)
/
/ output with expansion
__Variable expansion__:
Genus2 text: ${Genus2}
/
```opts :(document_opts)
screen_width: 80
```
@import bats-document-configuration.md