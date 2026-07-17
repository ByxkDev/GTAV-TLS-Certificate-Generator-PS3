# GTA ODT TLS Certificate Generator & EBOOT Certificate Patcher

The project creates a complete certificate chain:

```
Root CA
   |
   └── Intermediate CA
          |
          └── TLS Certificate
```
# Features

- Generates a private Root Certificate Authority
- Generates an Intermediate Certificate Authority
- Creates a TLS leaf certificate with SAN support
- Creates a full Go-compatible TLS certificate chain
- Exports a DER certificate (`.cer`) file
- Automatically patches a certificate slot inside `EBOOT.ELF`
- Creates a backup before modifying binaries
- Preserves the original EBOOT file size

---

# Requirements

## OpenSSL

Required for certificate generation.

Check installation:

```bash
openssl version
```

## Python 3

Required for EBOOT patching.

Check installation:

```bash
py --version
```

No additional Python packages are required.

---

# Project Structure

Example:

```
.
├── generate.sh
├── patch.py
├── EBOOT.ELF
├── README.md
│
└── tls/
    ├── root-ca.key
    ├── root-ca.pem
    ├── intermediate-ca.key
    ├── intermediate-ca.pem
    ├── tls.key
    ├── tls.crt
    └── tls.cer
```

# Generate Certificates

Run:

```bash
chmod +x generate-cert.sh
./generate-cert.sh
```

The script will remove any previous TLS folder and generate a new certificate hierarchy.

Output:

```
tls/
```

---

# Generated Files

| File | Description |
|---|---|
| `root-ca.key` | Root CA private key |
| `root-ca.pem` | Root CA certificate |
| `intermediate-ca.key` | Intermediate CA private key |
| `intermediate-ca.pem` | Intermediate CA certificate |
| `tls.key` | TLS private key |
| `tls.crt` | Complete TLS certificate chain |
| `tls.cer` | DER encoded certificate for EBOOT |

---

# Certificate Chain

The generated chain is:

```
TLS Certificate
        |
        |
Intermediate CA
        |
        |
Root CA
```

# EBOOT Patching

Place:

```
EBOOT.ELF
```

in the same directory as:

```
patch.py
```

Run:

```bash
py patch.py
```

The patcher will:

1. Create an automatic backup:

```
EBOOT.ELF.backup
```

2. Build the certificate chain:

```
eboot-chain.pem
```

using:

```
intermediate-ca.pem
root-ca.pem
```

3. Write the certificate chain into the EBOOT certificate area.

---

# Patch Location

The certificate is written using:

```
PATCH_OFFSET = 0x183FEB0
PATCH_SIZE = 3037
```

Current values:

```
Offset:
0x183FEB0

Certificate Slot Size:
3037 bytes
```

# Backup Restore

The original file is never overwritten without creating a backup.

## Missing files

The patcher requires:

```
EBOOT.ELF
../tls/intermediate-ca.pem
../tls/root-ca.pem
```

Make sure the paths match your folder layout.

---
