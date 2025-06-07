/ Import and require blocks with duplicate names.
/ Imported blocks appear first in the code because the import is at the top of the file.
@import import-duplicates-1.md
/ `d1` is required by `d0` in the import
``` :d0
echo d0.0
```
``` :d1
echo d0.1
```
``` :u0.0 +d0
echo u0.0
```
``` :u0.1 +d1
echo u0.1
```
@import bats-document-configuration.md