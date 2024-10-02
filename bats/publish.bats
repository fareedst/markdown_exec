#!/usr/bin/env bats

load 'test_helper'

@test 'Publish document file name - mode: write, name, format' {
  export MDE_PUBLISH_DOCUMENT_NAME_FORMAT='- %{document}'
  run bin/bmde \
   --publish-document-file-mode write \
   --publish-document-file-name /tmp/mde_file \
   docs/dev/specs.md \
   bash1
  [[ "$(cat /tmp/mde_file)" == "- ./docs/dev/specs.md" ]]
}

@test 'Publish block name - mode: write, name, format' {
  [ -f /tmp/mde_file ] && rm /tmp/mde_file
  export MDE_PUBLISH_BLOCK_NAME_FORMAT='++%{block}'
  export MDE_PUBLISH_DOCUMENT_NAME_FORMAT='--%{document}'
  run bin/bmde \
   --publish-document-file-mode append \
   --publish-document-file-name /tmp/mde_file \
   docs/dev/specs.md \
   bash1

  expect_equal_with_conversion "--./docs/dev/specs.md ++bash1 --./docs/dev/specs.md" "$(cat /tmp/mde_file)" "${BATS_OUTPUT_FILTER:-A}"
}
