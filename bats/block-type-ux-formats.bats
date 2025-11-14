#!/usr/bin/env bats

load 'test_helper'

@test 'displays UX block appearance by state' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-formats.md \
   'Demonstrate UX block appearance according to its state.__A simple variable declaration._EDIT VAR1 = value1__A selection from predefined options._ALLOW VAR2 = value2__A computed value using command substitution._ECHO VAR3 = Gemfile__An editable computed value._EDIT VAR4 = Gemfile__A command execution with formatted output._EXEC VAR5 = Gemfile___A read-only value._READONLY VAR6 = Gemfile_'
}
