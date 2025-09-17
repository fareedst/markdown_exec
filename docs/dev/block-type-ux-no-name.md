/ This automatic block sets multiple variables and displays the first variable.
```ux
echo:
  BASENAME1: "$(basename `pwd`)"
  DOCUMENTS1: "${BASENAME1%%_*}"
  OPERATION1: "${BASENAME1##*_}"
```
```ux
exec:
  BASENAME2: >-
    basename `pwd`
  DOCUMENTS2: >-
    echo "${BASENAME2%%_*}"
  OPERATION2: >-
    echo "${BASENAME2##*_}"
```
@import bats-document-configuration.md