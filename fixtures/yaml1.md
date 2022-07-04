- transformations are embedded in the script at every invocation
  with arguments to the transformation as stdin and stdout for the `yq` process
  eg `export fruit_summary=$(yq e '[.fruit.name,.fruit.price]' fruit.yml)`
  for invocation `%(summarize_fruits <fruit.yml =fruit_summary)`
  and transformation `[.fruit.name,.fruit.price]`

```yq :[summarize_fruits]
[.fruit.name,.fruit.price]
```

- write to: fruit.yml

```yaml :(make_fruit_file) >fruit.yml
fruit:
  name: apple
  color: green
  price: 1.234
```

- include summarize_fruits
- output value of var fruit_summary
- read from: fruit.yml
- result into var: fruit_summary instead of stdout

```bash :show_fruit_yml +(make_fruit_file) %(summarize_fruits <fruit.yml >$fruit_summary)
echo "fruit_summary: ${fruit_summary:-MISSING}"
```
