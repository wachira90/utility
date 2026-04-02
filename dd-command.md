# `dd` command to create a 1GB `.img` file

```bash
dd if=/dev/zero of=output.img bs=1M count=1024
```

### Explanation:

* `if=/dev/zero` → input file (fills with zeros)
* `of=output.img` → output file name
* `bs=1M` → block size (1 MB per block)
* `count=1024` → number of blocks → 1024 × 1MB = 1GB

---

### Faster alternative (sparse file, almost instant)

If you don’t need actual data written:

```bash
dd if=/dev/zero of=output.img bs=1 count=0 seek=1G
```

or even simpler:

```bash
truncate -s 1G output.img
```

---

### Optional: show progress

```bash
dd if=/dev/zero of=output.img bs=1M count=1024 status=progress
```

---

If you want a specific filesystem inside the `.img` (like ext4), I can show how to format and mount it too.
