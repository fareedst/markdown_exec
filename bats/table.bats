#!/usr/bin/env bats

load 'test_helper'

@test 'Tables - indented' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/table-indent.md \
   'DEMONSTRATE TABLE INDENTATION__Table flush at left._Centered columns._|    Common Name     |        Species         |   Genus    |   Family    | Year Discover |_| ------------------ | ---------------------- | ---------- | ----------- | ------------- |_| Tapanuli Orangutan |  Pongo tapanuliensis   |   Pongo    |  Hominidae  |     2017      |_| Psychedelic Frogfi | Histiophryne psychedel | Histiophry | Antennariid |     2009      |_|   Ruby Seadragon   |  Phyllopteryx dewysea  | Phyllopter | Syngnathida |     2015      |__  Table indented with two spaces._  Left-justified columns._  | Common Name               | Species       | Genus  | Family         | Year Discovere |_  | ------------------------- | ------------- | ------ | -------------- | -------------- |_  | Illacme tobini (Millipede | Illacme tobin | Illacm | Siphonorhinida | 2016           |__    Table indented with one tab._    Right-justified columns._    |     Common Name |             Species |     Genus |     Family | Year Discovered |_    | --------------- | ------------------- | --------- | ---------- | --------------- |_    | Spiny Dandelion | Taraxacum japonicum | Taraxacum | Asteraceae |            2022 |'
}

@test 'Tables - invalid' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/table-invalid.md \
  'Missing column names__| ------------------- | - |_| Pongo tapanuliensis |   |__Missing dividers__| Species_| Pongo tapanuliensis__Missing table rows__| Species |_| ------- |'
}
