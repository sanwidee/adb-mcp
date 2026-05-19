---
title: "Panduan Setup — Photoshop × Claude"
subtitle: "Edit file Photoshop pakai bahasa sehari-hari"
author: "Tim Desain"
---

# Apa ini?

Tools ini ngehubungin **Adobe Photoshop** sama **Claude Desktop**.
Kamu tinggal nulis instruksi pakai bahasa sehari-hari, Claude yang
ngerjain di Photoshop kamu — **semua layer tetap utuh**, bisa di-edit lagi.

**Contoh:**

> *"Resize file ini dari 1080×1080 ke 1080×1920 buat Instagram story, logo tetep di pojok kiri atas."*

> *"Duplicate halaman ini, ganti headline jadi 'Lebaran Sale 2026'."*

> *"Bikin variasi 3 warna background untuk semua frame, simpan ke folder Output."*

Cocok untuk: repurpose design, ganti copy bulk, resize aspect ratio,
variasi warna — semua tanpa rebuild dari nol.

---

# Yang Kamu Butuhkan

Sebelum mulai, pastikan ada:

- **Mac** dengan macOS 12 Monterey atau lebih baru
- **Adobe Photoshop 2025** (versi 26.0) atau lebih baru
- **Claude Desktop** terinstall ([download di sini](https://claude.ai/download))
- Ruang disk **minimal 5 GB**
- **Koneksi internet** stabil saat install (setelahnya bisa offline)
- **Password Mac** kamu

> **Tidak perlu** install Homebrew, Python, atau Node sendiri.
> Installer otomatis nge-handle semua itu.

\newpage

# Bagian 1: Setup (Sekali Aja, ±10 Menit)

## Langkah 1 — Extract Folder

Extract folder `adobe-mcp` yang kamu terima ke tempat yang gampang
diakses. Misalnya di `~/Documents/adobe-mcp/`.

Folder akan berisi 3 file:

```
adobe-mcp/
├── install_setup.sh       ← installer (Langkah 3)
├── StartSession.command   ← launcher harian
└── README.md              ← dokumentasi singkat
```

## Langkah 2 — Buka Terminal

Tekan **`Cmd + Space`** → ketik **Terminal** → tekan Return.

Akan kebuka jendela hitam/putih dengan prompt.

## Langkah 3 — Jalankan Installer

Di Terminal, ketik `bash ` (dengan spasi di belakang), lalu **drag file
`install_setup.sh` dari Finder ke jendela Terminal**. Path-nya akan
otomatis ke-paste. Hasilnya kira-kira:

```bash
bash ~/Documents/adobe-mcp/install_setup.sh
```

Tekan Return.

### Yang Akan Terjadi

Installer berjalan dalam 10 fase. Tiap fase ditandai dengan `[X/10]`:

| Fase | Keterangan | Waktu |
|------|------------|-------|
| 1 | Cek macOS, disk, internet | <5 detik |
| 2 | Install Xcode Command Line Tools *(kalau Mac belum pernah pakai)* | 10–25 menit |
| 3 | Cek Photoshop & Claude Desktop | <5 detik |
| 4 | Install Homebrew | 1–2 menit |
| 5 | Install Python, Node, uv, jq | 2–5 menit |
| 6 | Download adb-mcp dari GitHub | 30 detik |
| 7 | Install dependencies Python | 1–2 menit |
| 8 | Install dependencies Node | 30 detik |
| 9 | Konfigurasi Claude Desktop | <5 detik |
| 10 | Verifikasi semua jalan | <5 detik |

### Hal-Hal Penting Saat Installer Jalan

**A. Kalau muncul popup "Xcode Command Line Tools"**

Ini cuma terjadi kalau Mac kamu **belum pernah install development
tools**. Yang harus dilakukan:

1. Klik tombol **"Install"** (BUKAN "Get Xcode" — itu IDE yang gede banget)
2. Klik **"Agree"** untuk EULA
3. **Tunggu 10–25 menit** sampai download selesai
4. Terminal akan keliatan diem dengan spinner berputar — itu normal,
   jangan ditutup

**B. Kalau diminta password**

Akan muncul `Password:` di Terminal. Ketik password Mac kamu, lalu Return.

> **Karakter password tidak akan keliatan di layar** — itu fitur
> keamanan macOS, bukan bug. Tetap ketik aja terus dengan benar.

**C. Kalau prompt kamu ada `(base)` di depan**

Itu artinya Anaconda aktif di Mac kamu. Sebelum jalanin installer,
matiin dulu:

```bash
conda deactivate
```

Lalu jalanin installer lagi.

\newpage

### Hasil Akhir Installer

Setelah selesai, kamu akan lihat banner hijau:

```
════════════════════════════════════════════════════════
  ✅ Automated setup complete.
════════════════════════════════════════════════════════

ONE MANUAL STEP REMAINS — load the UXP plugin in Photoshop.
```

Lanjut ke Langkah 4.

## Langkah 4 — Install UXP Developer Tool (UDT)

Ini tools dari Adobe yang dipakai buat load plugin Claude ke Photoshop.
**Sekali install saja.**

1. Buka link ini di browser:
   `https://developer.adobe.com/photoshop/uxp/2022/guides/devtool/`
2. Download **UXP Developer Tool**
3. Install seperti app biasa (drag ke folder Applications)

## Langkah 5 — Load Plugin ke Photoshop

Ini satu-satunya langkah manual yang **tidak bisa di-otomatisasi**
(aturan Adobe).

### 5a. Persiapan

1. **Buka Photoshop dulu.** Tunggu sampai welcome screen muncul atau
   workspace siap.
2. Enable Developer Mode:
   - **Photoshop → Settings → Plug-ins**
   - Centang **"Enable Developer Mode"**
   - Klik OK. Restart Photoshop kalau diminta.

### 5b. Add Plugin di UDT

1. Buka **UXP Developer Tool**
2. Klik tombol biru **"Add Plugin..."** di pojok kanan atas
3. Di dialog yang muncul, tekan **`Cmd + Shift + G`** untuk "Go to Folder"
4. Paste path ini:
   ```
   ~/tools/adb-mcp/uxp/ps/manifest.json
   ```
5. Klik file `manifest.json` yang ke-highlight → klik **"Select"**

### 5c. Load Plugin

1. Di list UDT, akan muncul baris **"Photoshop MCP Agent"** dengan
   status `Not loaded`
2. Klik tombol **"⏵ Load & Watch"** (lingkaran dengan ikon play di kolom
   Actions)
3. Status berubah jadi **`Loaded`** (titik hijau)
4. Lihat tab **UDT LOGS** di bawah — pastikan tidak ada error merah

### 5d. Buka Panel di Photoshop

Di Photoshop, klik menu **`Plugins`** di menu bar atas → klik
**"Photoshop MCP Agent"**.

Panel kecil (300×200 px) akan muncul di workspace. Drag ke pinggir
biar nyatu sama panel Layers/Properties.

---

**Setup selesai!** Step 4 dan 5 **tidak perlu diulang** selama
Photoshop tidak di-uninstall.

\newpage

# Bagian 2: Penggunaan Harian

## Cara Memulai Sesi Kerja

### Step A — Start Proxy Server

1. Buka **Finder** → masuk ke folder `adobe-mcp`
2. **Double-click `StartSession.command`**
3. Jendela Terminal kebuka, tunggu sampai muncul:
   ```
   ✅ Ready. Open Photoshop + Claude Desktop.
   ```
4. **Jangan tutup Terminal ini.** Boleh di-minimize.

> **Cuma pertama kali:** macOS bisa bilang *"unidentified developer"*.
> Klik kanan file → **Open** → **Open**. Setelahnya double-click biasa.

### Step B — Buka Photoshop & Connect Panel

1. Buka **Photoshop** kalau belum
2. Panel **"Photoshop MCP Agent"** akan auto-connect ke proxy
   (karena "Connect on Launch" sudah dicentang)
3. Pastikan tombol panel menampilkan **"Disconnect"** — artinya **sudah
   terhubung**

### Step C — Buka Claude Desktop & Mulai Ngobrol

1. Buka **Claude Desktop**
2. Buka chat baru
3. Buka file PSD kamu di Photoshop
4. Mulai instruksi ke Claude pakai bahasa sehari-hari

## Cara Mengakhiri Sesi

1. Klik jendela Terminal yang running `StartSession.command`
2. Tekan **`Ctrl + C`**
3. Akan muncul **"Proxy stopped. Goodbye."**
4. Tutup jendela Terminal

## Contoh Prompt Yang Bisa Dicoba

### Tingkat Mudah

- *"Lihat layer apa aja di dokumen aktif"*
- *"Bikin layer text baru bertuliskan 'Hello' di tengah canvas, font Helvetica size 72"*
- *"Resize dokumen ini ke 1080×1920"*
- *"Ganti warna background layer 'BG' jadi #FF5733"*

### Tingkat Menengah

- *"Duplicate dokumen ini, ganti headline di layer 'title' jadi 'Lebaran Sale 2026', save as PSD baru"*
- *"Buat 3 variasi background color (merah, biru, hijau) tanpa mengubah layer lain"*
- *"Resize ke aspect ratio 4:5, anchor center, layer logo tetap di pojok kiri atas"*

### Tingkat Advanced

- *"Convert dokumen ini ke variant Instagram feed (1080×1080) dan story (1080×1920), simpan dua-duanya ke ~/Desktop/output, semua layer text tetap editable"*
- *"Ambil semua frame berisi headline, ganti text-nya jadi versi bahasa Inggris (terjemahkan otomatis)"*

\newpage

# Bagian 3: Troubleshooting

## Masalah Umum & Solusinya

### Installer Stuck Lama Di `[2/10]`

**Penyebab:** Xcode Command Line Tools sedang di-download (1.5 GB).

**Solusi:** Tunggu. Bisa makan 10–25 menit tergantung internet. Cek
Dock — kalau popup "Install Xcode CLT" ada di sana tapi ke-minimize,
klik biar muncul lagi.

### "Password:" Muncul Tapi Tidak Bisa Ngetik

**Penyebab:** Bukan tidak bisa, cuma karakter password sengaja
disembunyikan oleh macOS.

**Solusi:** Tetap ketik password kamu dengan benar, lalu Return.

### Plugin Load Failed di UDT

**Solusi berurutan:**

1. **Quit Photoshop sepenuhnya** (Cmd+Q)
2. **Quit UDT sepenuhnya** (Cmd+Q)
3. Buka **Photoshop** dulu, tunggu fully loaded
4. Buka **UDT**, klik **"Load & Watch"** (bukan "Load" biasa)
5. Kalau masih gagal: **Remove** plugin di UDT → **Add Plugin** lagi →
   **Load & Watch**

### Panel Claude Tidak Muncul di Photoshop

**Solusi:** Di Photoshop, klik **`Plugins`** di menu bar atas → cari
**"Photoshop MCP Agent"** → klik untuk munculin panel.

### Claude Desktop Tidak Lihat Tool "photoshop"

**Solusi:**

1. **Quit Claude Desktop sepenuhnya** (`Cmd + Q`, bukan close window)
2. Pastikan `StartSession.command` masih running di Terminal
3. Buka Claude Desktop lagi
4. Cek di **Settings → Developer → Local MCP servers** —
   `photoshop` harus berstatus connected

### Server `photoshop` Status "Failed"

**Solusi:** Jalankan ulang `install_setup.sh`. Script-nya idempotent
(aman di-rerun, tidak akan rusakin yang sudah ke-install).

### Panel Photoshop Bilang "Disconnected"

**Solusi:**

1. Pastikan Terminal `StartSession.command` masih running
2. Klik tombol **"Connect"** di panel Photoshop
3. Kalau masih gagal: close Terminal, double-click
   `StartSession.command` lagi, klik Connect lagi

### `StartSession.command` Diblokir macOS

**Penyebab:** macOS pertama kali tidak percaya file dari source unknown.

**Solusi:** Klik kanan `StartSession.command` di Finder → **Open** →
**Open** (sekali aja). Selanjutnya double-click biasa.

\newpage

# Bagian 4: Untuk Yang Penasaran

## Apa Yang Berjalan Di Belakang Layar?

Saat kamu pakai sistem ini, ada **3 komponen** yang berinteraksi:

```
┌─────────────┐      ┌────────────┐      ┌──────────────┐      ┌─────────────┐
│   Claude    │◄────►│ MCP Server │◄────►│ Node Proxy   │◄────►│  Photoshop  │
│   Desktop   │      │  (Python)  │      │ (port 3001)  │      │ UXP Plugin  │
└─────────────┘      └────────────┘      └──────────────┘      └─────────────┘
```

- **Claude Desktop** — yang ngobrol sama kamu
- **MCP Server (Python)** — diluncurin otomatis sama Claude Desktop
  saat startup. Menerjemahkan request Claude jadi command untuk Photoshop.
- **Node Proxy** — diluncurin sama `StartSession.command`. Mediator
  antara MCP Server dan UXP Plugin di Photoshop. Listen di port `3001`.
- **UXP Plugin** — running di dalam Photoshop. Eksekusi command yang
  diterima dari proxy.

## Lokasi File Penting

| File | Lokasi |
|------|--------|
| Repo adb-mcp | `~/tools/adb-mcp/` |
| Plugin manifest | `~/tools/adb-mcp/uxp/ps/manifest.json` |
| Proxy log (kalau ada error) | `~/tools/adb-mcp/.logs/proxy.log` |
| Konfigurasi Claude Desktop | `~/Library/Application Support/Claude/claude_desktop_config.json` |
| Log Claude Desktop MCP | `~/Library/Logs/Claude/mcp-server-photoshop.log` |

## Untuk Update ke Versi Terbaru

Cukup jalankan ulang installer:

```bash
bash ~/Documents/adobe-mcp/install_setup.sh
```

Script-nya akan:

- Pull versi terbaru `adb-mcp` dari GitHub
- Update dependencies kalau ada yang baru
- Tidak rusakin konfigurasi yang sudah ada

---

# Bantuan & Support

- **Repo upstream:** github.com/mikechambers/adb-mcp
- **Dibikin oleh:** Mike Chambers (Adobe)
- **Lisensi:** MIT

Kalau ada masalah yang tidak ke-cover di Troubleshooting, sertakan:

1. Screenshot Terminal saat error
2. Screenshot UDT LOGS (kalau plugin load error)
3. Output dari: `cat ~/Library/Logs/Claude/mcp-server-photoshop.log`
