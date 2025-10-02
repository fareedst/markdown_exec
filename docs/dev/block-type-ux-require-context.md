/ Neither block is evaluated at initialization.
/ When the first UX block is activated, it is evaluated.
/ The variable set in the first UX block is available to the second,
/ which is required by the first, resulting in its evaluation.
```ux :[ux1] +[ux2] +(ENTITY)
act: :echo
echo:
  UX1: '$ENTITY'
format: |-
  Get the common name...
init: false
```
/ The shell required code and the first evaluated UX block are the context
/ when the the `echo` expressions are being evaluated in the second UX block.
/ The first evaluated UX block is the context when the `format` value is being expanded.
```ux :[ux2]
act: :echo
echo:
  UX2: '$UX1'
  ENTITY2: '$ENTITY'
format: |-
  Entity: ${ENTITY}
  ENTITY2: ${ENTITY2}
  UX1: ${UX1}
  Common name: ${UX2}
init: false
readonly: true
```
```bash :(ENTITY)
ENTITY='Mythical Monkey'
```
@import bats-document-configuration.md