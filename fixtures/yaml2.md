`yq e '.coins[] | {"name": .name, "price": .price}' coins.yml`

```yq :[extract_coins_report]
.coins | map(. | { "name": .name, "price": .price })
```

```yaml :(make_coins_file) >$coins
coins:
  - name: bitcoin
    price: 21000
  - name: ethereum
    price: 1000
```

```bash :show_coins_var +(make_coins_file) %(extract_coins_report <$coins >$coins_report)
echo "coins_report:"
echo "${coins_report:-MISSING}"
```

```bash :report_coins_yml +(make_coins_file) %(extract_coins_report <$coins >tmp/coins_report.yml)
echo "coins_report:"
cat tmp/coins_report.yml
rm tmp/coins_report.yml
```
