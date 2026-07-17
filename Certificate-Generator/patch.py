import os
import shutil


EBOOT = "EBOOT.ELF"
BACKUP = "EBOOT.ELF.backup"

INTERMEDIATE = "../tls/intermediate-ca.pem"
ROOT = "../tls/root-ca.pem"
CHAIN = "eboot-chain.pem"

PATCH_OFFSET = 0x183FEB0
PATCH_SIZE = 3037

def read_file(path):
    with open(path, "rb") as f: data = f.read()
    data = data.replace(b"\r\n", b"\n")
    data = data.rstrip(b"\r\n\t ")
    return data

def create_chain():
    if not os.path.isfile(INTERMEDIATE):
        raise FileNotFoundError(INTERMEDIATE)

    if not os.path.isfile(ROOT):
        raise FileNotFoundError(ROOT)

    intermediate = read_file(INTERMEDIATE)
    root = read_file(ROOT)

    chain = (intermediate + b"\n" + root + b"\n")

    with open(CHAIN, "wb") as f: 
        f.write(chain)

    print("[+] Created:", CHAIN)
    print("[+] Chain size:", len(chain))
    return CHAIN



def patch(fp, offset, size, cert_file):

    cert = read_file(cert_file)
    cert += b"\n"

    print()
    print("[*] Offset : 0x%X" % offset)
    print("[*] Slot   :", size)
    print("[*] Size   :", len(cert))

    if len(cert) > size: 
        raise RuntimeError(f"Chain too large: {len(cert)} > {size}")

    fp.seek(offset)
    fp.write(cert)
    remaining = size - len(cert)

    if remaining: fp.write(b"\x00" * remaining)

    print("[OK] Certificate patched")



def main():

    if not os.path.isfile(EBOOT): 
        print("[!] Missing:", EBOOT) return

    if not os.path.isfile(BACKUP):
        shutil.copy2(EBOOT, BACKUP)
        print("[+] Backup created:", BACKUP)
    else:
        print("[*] Backup already exists")

    chain = create_chain()

    with open(EBOOT, "r+b") as fp: 
        patch(fp, PATCH_OFFSET, PATCH_SIZE, chain)

    print()
    print("[OK] Finished")
    print("[OK] EBOOT size:", os.path.getsize(EBOOT))

if __name__ == "__main__":
    main()