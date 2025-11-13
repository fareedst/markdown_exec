```ux
echo: Tapanuli Orangutan
name: COMMON_NAME
```
@import import-parameter-symbols-template.md \
  NAMEC:cq='printf %s "$COMMON_NAME"' \
  NAMEE:eq=$COMMON_NAME \
  NAMEL="Tapanuli Orangutan" \
  NAMEQ:qq="Tapanuli Orangutan" \
  NAMEV:vq=COMMON_NAME
@import bats-document-configuration.md
```opts :(document_opts)
dump_inherited_lines: false
```