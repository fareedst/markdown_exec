#!/usr/bin/env bats

load 'test_helper'

@test 'Tables - truncate columns' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/table-column-truncate.md \
   'DEMONSTRATE TRUNCATION OF TEXT IN TABLE CELLS__| Common Name  | Species      | Genus |  Family | Year Di |_| ------------ | ------------ | ----- | ------- | ------- |_| Tapanuli Ora | Pongo tapanu | Pongo | Hominid |  2017   |_| Psychedelic  | Histiophryne | Histi | Antenna |  2009   |_| Ruby Seadrag | Phyllopteryx | Phyll | Syngnat |  2015   |_| Illacme tobi | Illacme tobi | Illac | Siphono |  2016   |_| Spiny Dandel | Taraxacum ja | Tarax | Asterac |  2022   |__'
}
