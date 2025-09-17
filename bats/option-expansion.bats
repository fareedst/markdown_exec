#!/usr/bin/env bats

load 'test_helper'

@test '' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/option-expansion.md \
   '_| Opti | Description                  | Valu | Va | Defau |_| ---- | ---------------------------- | ---- | -- | ----- |_| scre | Screen width for document an | 2    | 64 | 0     |_| tabl |                              | 5    | fa | true  |'
}
