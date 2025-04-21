#!/usr/bin/env bats

load 'test_helper'

@test '' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/option-expansion.md \
   '_| Optio | Description                      | Value | Va | Def |_| ----- | -------------------------------- | ----- | -- | --- |_| scree | Screen width for document and in | 2     | 64 | 0   |_| table |                                  | 5     | fa | tru |'
}
