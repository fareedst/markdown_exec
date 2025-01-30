#!/usr/bin/env bats

load 'test_helper'

@test 'Text and Headings' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/line-wrapping.md \
   "          DEMO WRAPPING LONG LINES__MDE detects the screen's dimensions:_height (lines) and width (characters)__Normal document text is displayed as_disabled menu lines. The width of these_lines is limited according to the screen's_width.__Test Indented Lines__  Indented with two spaces, this line_  should wrap in an aesthetically pleasing_  way.__    Indented with a tab, this line should_    wrap in an aesthetically pleasing way.__  SPECIES GENUS FAMILY ORDER CLASS PHYLUM_               KINGDOM DOMAIN_species genus family order class phylum_kingdom domain"
}
