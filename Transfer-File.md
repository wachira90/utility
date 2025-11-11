# Transfer File

ถ้า “ไฟล์ใหญ่” และผ่าน SSH ทั้งคู่—ตัวเลือกหลักคือ **rsync**, **scp**, และ **sftp** (พร้อม reget/resume). เลือกยังไงดี? สรุปสั้น ๆ พร้อมคำสั่งตัวอย่างให้เลย

# ควรใช้ตัวไหน

* **ต้องโอนไฟล์/โฟลเดอร์ใหญ่ ๆ และอยาก resume ได้, ทวนความถูกต้อง, sync ซ้ำ ๆ**
  → ใช้ **`rsync`** เหมาะสุด
  จุดเด่น: resume ได้, โอนเฉพาะส่วนที่ต่าง (delta), จำกัดแบนด์วิธได้, มี progress ดี, ตรวจ checksum ได้

* **โอนไฟล์ครั้งเดียวแบบง่าย ๆ (single shot) และเน็ตเสถียร**
  → **`scp`** พอได้ (ง่ายสุด)
  ข้อเสีย: resume ไม่ดีเท่า rsync, ไม่มี delta

* **โอนไฟล์เดียวแล้วอยาก “กดต่อจากเดิม” โดยไม่ติดตั้งเพิ่ม**
  → **`sftp`** ใช้คำสั่ง `reget`/`reput` ได้ (resume ได้ แต่ไม่มี delta)

* **หลายไฟล์เล็กจำนวนมากบน LAN และอยากลด overhead จาก metadata**
  → **`tar` over SSH** หรือ **`rsync -W`** (whole-file) จะเร็วกว่า

---

# สูตรคำสั่งที่ใช้จริงบ่อย

## 1) rsync: ไฟล์ใหญ่/หลายไฟล์, resume ได้

```bash
# ไฟล์เดียว/โฟลเดอร์ พร้อม progress + resume + verify
rsync -avP --partial --append-verify \
  /path/to/src  user@host:/path/to/dst

# ถ้าข้อมูลบีบอัดได้ดี (เช่น text, csv) ค่อยเปิด -z
rsync -avP -z --partial --append-verify /data/ user@host:/data/

# จำกัดแบนด์วิธ (เช่น 80 MB/s = 640000 Kbps)
rsync -avP --bwlimit=640000 /data user@host:/data

# mirror จริงจัง (ระวัง --delete!)
rsync -aHAXx --info=progress2 --partial --append-verify --delete \
  /mnt/src/  user@host:/mnt/dst/
```

ทิป:

* WAN latency สูง/ไฟล์มหึมา: พิจารณา `--inplace` (ลด I/O สองเท่า) แต่ระวัง snapshot/backup
* ตรวจเข้มสุด ๆ: เพิ่ม `--checksum` (ช้าลงแต่ชัวร์) หรือบน rsync รุ่นใหม่ใช้ `--checksum-choice=xxh3`

## 2) scp: ง่าย เร็ว เรียบ

```bash
# ครั้งเดียวจบ
scp /big/file.iso user@host:/dst/

# ถ้าข้อมูลบีบอัดได้ดีเท่านั้นค่อยเปิด -C (ถ้าไฟล์ .iso/.zip/.tar.gz มักไม่ช่วย)
scp -C /logs/big.txt user@host:/dst/

# จำกัดแบนด์วิธ (หน่วย Kbit/s)
scp -l 80000 /big/file.iso user@host:/dst/
```

ทิปความเร็ว:

* CPU มี AES-NI: ใช้ `-c aes128-gcm@openssh.com`
* CPU ไม่มี AES เร็ว: ใช้ `-c chacha20-poly1305@openssh.com`

## 3) sftp: resume แบบเนทีฟ

```bash
sftp user@host
sftp> put -P /big/file.iso    # -P = แสดง progress
# ถ้าหลุด
sftp> reget /big/file.iso
```

## 4) tar over SSH: หลายไฟล์เล็กจำนวนมาก

```bash
# bundle แล้วส่งท่อเดียว ลด syscalls/round-trip
tar -cf - /path/to/dir | ssh user@host 'tar -xf - -C /dst/'
# ใส่ pv เพื่อเห็นความเร็ว (ต้องติดตั้ง pv ก่อน)
tar -cf - /path | pv | ssh user@host 'tar -xf - -C /dst/'
```

---

# แนวทางเลือกให้เหมาะ (Decision Tips)

* โอนไฟล์/โฟลเดอร์ใหญ่มาก ๆ, โอนซ้ำบ่อย, กลัวหลุดกลางทาง → **rsync** (แนะนำสุด)
* โอนครั้งเดียว, โครงสร้างไม่ซับซ้อน → **scp**
* ต้อง “ต่อจากที่ค้าง” โดยไม่อยากเปลี่ยนเครื่องมือ → **sftp reget**
* LAN เร็วมาก, ไฟล์เล็กเพียบ → **tar|ssh** หรือ **rsync -W**

# เรื่อง Performance/ความเสถียรที่ควรรู้

* **Compression**: เปิดเฉพาะข้อมูลที่บีบอัดได้ (text, csv). ไฟล์ที่บีบอัดอยู่แล้ว (.zip/.gz/.iso/.mp4) เปิด -C/-z จะช้าลง
* **Cipher**: `chacha20-poly1305@openssh.com` มักเร็วบน CPU ทั่วไป; `aes128-gcm@openssh.com` เร็วบนเครื่องที่มี AES-NI
* **Bandwidth control**: ใช้ `--bwlimit` (rsync) หรือ `-l` (scp) กันลิงก์ตัน
* **Verify หลังโอน**: ใช้ `rsync --checksum` หรือเทียบ `sha256sum` ต้นทาง/ปลายทาง

สรุป: สำหรับงานสาย Infra/Prod โอนใหญ่ ๆ ให้ **เริ่มที่ rsync** เป็นค่าเริ่มต้น (เพิ่ม `-avP --partial --append-verify`), ส่วน `scp` เหมาะกับเคสง่าย ๆ ครั้งเดียวจบ และ `sftp reget` ใช้เวลาต้องต่อไฟล์เดิมแบบตรงไปตรงมา.
