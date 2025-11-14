#!/usr/bin/env bats

load 'test_helper'

@test 'renders indented tables' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/table-indent.md \
   'DEMONSTRATE TABLE INDENTATION__Table flush at left._Centered columns._|    Common Name     |         Species         |    Genus    |    Family    | Year Discovered |_| ------------------ | ----------------------- | ----------- | ------------ | --------------- |_| Tapanuli Orangutan |   Pongo tapanuliensis   |    Pongo    |  Hominidae   |      2017       |_| Psychedelic Frogfi | Histiophryne psychedeli | Histiophryn | Antennariida |      2009       |_|   Ruby Seadragon   |  Phyllopteryx dewysea   | Phylloptery | Syngnathidae |      2015       |__  Table indented with two spaces._  Left-justified columns._  | Common Name                | Species        | Genus   | Family          | Year Discovered |_  | -------------------------- | -------------- | ------- | --------------- | --------------- |_  | Illacme tobini (Millipede) | Illacme tobini | Illacme | Siphonorhinidae | 2016            |__    Table indented with one tab._    Right-justified columns._    |     Common Name |             Species |     Genus |     Family | Year Discovered |_    | --------------- | ------------------- | --------- | ---------- | --------------- |_    | Spiny Dandelion | Taraxacum japonicum | Taraxacum | Asteraceae |            2022 |'
}

@test 'reports invalid table errors' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/table-invalid.md \
  'Missing column names__| ------------------- | - |_| Pongo tapanuliensis |   |__Missing dividers__| Species_| Pongo tapanuliensis__Missing table rows__| Species |_| ------- |'
}
