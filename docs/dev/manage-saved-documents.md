```history :list_documents_in_directory
directory: document_configurations/instances
filename_pattern: '^(?<name>.*)$'
glob: '*'
view: '%{name}'
```
```load :load_document_from_directory
directory: document_configurations/instances
filename_pattern: '^(?<name>.*)$'
glob: '*'
view: '%{name}'
```
```view :view
```
```edit :edit
```
```save :save_document_in_directory
directory: document_configurations/instances
filename_pattern: '^(?<name>.*)$'
glob: '*'
view: '%{name}'
```