#!/usr/bin/env bats

load 'test_helper'

@test 'truncates text in table columns' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/table-column-truncate.md \
   'DEMONSTRATE TRUNCATION OF TEXT IN TABLE CELLS__| Common Name         | Species            | Genus    |      Family | Year Discover |_| ------------------- | ------------------ | -------- | ----------- | ------------- |_| Tapanuli Orangutan  | Pongo tapanuliensi | Pongo    |   Hominidae |     2017      |_| Psychedelic Frogfis | Histiophryne psych | Histioph | Antennariid |     2009      |_| Ruby Seadragon      | Phyllopteryx dewys | Phyllopt | Syngnathida |     2015      |_| Illacme tobini (Mil | Illacme tobini     | Illacme  | Siphonorhin |     2016      |_| Spiny Dandelion     | Taraxacum japonicu | Taraxacu |  Asteraceae |     2022      |_'
}
