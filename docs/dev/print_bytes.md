```bash :(document_shell)
print_bytes () { printf %s "$1" | hexdump -v -e '16/1 " %02x"' ; }
```