#!/usr/bin/env bats

load 'test_helper'

# Imported blocks `[du]1.*` appear before principal blocks `[du]0.*` in the code evaluated because the import of `import-duplicates-1.md` is above the `0.*` definitions in the principal file.

@test 'Import and require blocks with duplicate names - unique in main 0' {
  BATS_OUTPUT_FILTER=A
  BATS_SAFE=_
  spec_mde_args_expect docs/dev/import-duplicates-0.md \
   'u0.0' \
   '_d1.0_d1.1_d0.0_d0.1_u0.0'
}

@test 'Import and require blocks with duplicate names - unique in main 1' {
  BATS_OUTPUT_FILTER=A
  BATS_SAFE=_
  spec_mde_args_expect docs/dev/import-duplicates-0.md \
   'u0.1' \
   '_d1.1_d0.1_u0.1'
}

# a name in the CLI that matches multiple blocks only loads the first
@test 'Import and require blocks with duplicate names - duplicate 0' {
  BATS_OUTPUT_FILTER=A
  BATS_SAFE=_
  spec_mde_args_expect docs/dev/import-duplicates-0.md \
   'd0' \
   '_d1.0_d1.1_d0.1'
}

# a name in the CLI that matches multiple blocks only loads the first
@test 'Import and require blocks with duplicate names - duplicate 1' {
  BATS_OUTPUT_FILTER=A
  BATS_SAFE=_
  spec_mde_args_expect docs/dev/import-duplicates-0.md \
   'd1' \
   '_d1.1'
}

@test 'Import and require blocks with duplicate names - unique in import 0' {
  BATS_OUTPUT_FILTER=A
  BATS_SAFE=_
  spec_mde_args_expect docs/dev/import-duplicates-0.md \
   'u1.0' \
   '_d1.0_d1.1_u1.0_d0.0_d0.1'
}

@test 'Import and require blocks with duplicate names - unique in import 1' {
  BATS_OUTPUT_FILTER=A
  BATS_SAFE=_
  spec_mde_args_expect docs/dev/import-duplicates-0.md \
   'u1.1' \
   '_d1.1_u1.1_d0.1'
}
