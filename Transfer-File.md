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

# How to test 


ได้เลย—มีหลายวิธีบน Linux ที่จะ “ทดสอบและกะเวลา” โอนถ่ายไฟล์ระหว่างสองเครื่องให้ใกล้เคียงความจริงมากที่สุด ขึ้นกับว่าคุณอยากวัดเฉพาะเครือข่าย หรือวัด end-to-end (อ่านดิสก์ → เข้ารหัส/ส่ง → เขียนดิสก์)

# 1) วัดเพดานความเร็วเครือข่ายด้วย `iperf3` (เร็วและแม่นเรื่องลิงก์)

**ปลายทาง (รับ):**

```bash
iperf3 -s
```

**ต้นทาง (ส่ง):**

```bash
iperf3 -c <IP-ปลายทาง> -P 4
```

ดูค่ารวม `Mbits/sec` ที่ท้ายผลลัพธ์ (เช่น 820 Mbits/sec)

**คำนวณเวลาโดยคร่าว:**

```
เวลา(นาที) ≈ ขนาดไฟล์(GB-ทศนิยม) × 8 / ความเร็ว(Mbits/sec) / 60
```

ตัวอย่าง: 120 GB ที่ 820 Mbits/sec ⇒ 120×8/820/60 ≈ 0.19 ชม. ≈ 11.7 นาที
*หมายเหตุ:* iperf3 วัดเฉพาะเครือข่าย ไม่รวมดิสก์/CPU และ overhead ของ SSH

# 2) วัด end-to-end ผ่าน SSH ด้วย `pv` (รวม encryption + network และเลือกจะรวม I/O ดิสก์ได้)

## 2.1 วัด “ส่งจริงแต่ทิ้งปลายทาง” (ไม่เขียนดิสก์ปลายทาง)

```bash
# บนต้นทาง
pv /path/to/bigfile | ssh user@dest "cat > /dev/null"
```

ดูความเร็วเฉลี่ยจาก `pv` (MB/s) แล้วคำนวณเวลา = ขนาดไฟล์(GB) ÷ ความเร็ว(GB/s)

## 2.2 วัดครบลูป “อ่านดิสก์ต้นทาง → ส่ง → เขียนดิสก์ปลายทาง”

```bash
pv /path/to/bigfile | ssh user@dest "cat > /mnt/target/testfile"
```

อันนี้สะท้อนของจริงที่สุด (ดิสก์สองฝั่ง + CPU + เครือข่าย + SSH)

> ทิป: ถ้าไฟล์จริงใหญ่มาก แต่อยาก “ลองยกน้ำหนัก” ก่อน
> สร้างไฟล์ทดสอบ ~5–20GB:
>
> ```bash
> fallocate -l 10G /tmp/test.img             # เร็วและไม่กิน CPU
> pv /tmp/test.img | ssh user@dest "cat > /mnt/target/test.img"
> ```

# 3) ให้เครื่องมือบอก ETA ให้เลย (ง่ายสุด)

## 3.1 `rsync` แสดงความเร็วและ ETA

```bash
rsync -av --info=progress2 -e "ssh -T -o Compression=no -c aes128-gcm@openssh.com" \
  /path/to/bigfile user@dest:/mnt/target/
```

`--info=progress2` จะโชว์ speed/ETA รวมไฟล์ทั้งหมด ขอยกเลิกกลางคันได้ (Ctrl+C) ถ้าแค่อยากรู้ความเร็วประมาณการ

## 3.2 `scp` ก็มี ETA

```bash
scp /path/to/bigfile user@dest:/mnt/target/
```

ระหว่างรันจะแสดงเปอร์เซ็นต์ ความเร็ว และเวลาโดยประมาณ

# 4) สคริปต์คำนวณเวลาแบบเร็วบนเชลล์

กรณีคุณรู้อยู่แล้วว่า “สปีดที่ทำได้จริง” เท่าไร (เช่นจาก iperf3 หรือ pv):

```bash
# SIZE_GB = ขนาดไฟล์หน่วย GB (ทศนิยม), SPEED_MBPS = ความเร็วจริงหน่วย Mbits/sec
SIZE_GB=120
SPEED_MBPS=600
echo "scale=2; $SIZE_GB*8/$SPEED_MBPS*60" | bc   # นาที
```

หรือถ้าได้เป็น MB/s (จาก pv/rsync):

```bash
SIZE_GB=120
SPEED_MBPSec=75   # 75 MB/s
echo "scale=2; $SIZE_GB*1024/$SPEED_MBPSec/60" | bc
```

# ข้อควรระวังที่ทำให้ ETA เพี้ยน

* **ดิสก์ช้า**: ความเร็วจริง = ค่าต่ำสุดของ (อ่านดิสก์ต้นทาง, เครือข่าย, เขียนดิสก์ปลายทาง, CPU/เข้ารหัส)
* **SSH เข้ารหัส**: เปลี่ยนอัลกอริทึมที่เบาอย่าง `-c aes128-gcm@openssh.com` และปิด `Compression` หากลิงก์กว้าง
* **ไฟล์เล็กจำนวนมาก**: throughput จะตกกว่าก้อนใหญ่—rsync มักทำได้ดีกว่า scp
* **Wi-Fi/Internet ข้ามไซต์**: latency และ jitter ทำให้สปีดแกว่ง—ใช้ `iperf3 -P` (หลายสตรีม) จะเข้าใกล้เพดานมากขึ้น

ถ้าต้องการ “ตัวเลขนาทีที่เชื่อถือได้” แนะนำลำดับนี้:

1. รัน `iperf3` หาเพดานลิงก์ → 2) รัน `pv | ssh` เขียนลงดิสก์ปลายทาง 5–10GB → 3) ใช้สคริปต์คำนวณเวลาจากความเร็วเฉลี่ยที่เห็น
   สามขั้นนี้จะได้ ETA ที่ค่อนข้างตรงกับงานจริงโดยไม่ต้องโอนไฟล์ทั้งก้อนก่อนครับ.



