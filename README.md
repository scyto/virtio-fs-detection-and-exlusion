# 🛡️ VFIO PCI Passthrough Setup for NVMe & SATA Devices (Boot-Safe)

This repo helps safely bind selected PCI storage devices (NVMe, SATA) to `vfio-pci` **early in boot**, before the kernel or systemd services can claim them — ideal for PCI passthrough to VMs or containers.

**NOTE** this script is only needed if you can't use the classic device blacklisting in the proxmox wiki

---

## 🧰 Requirements

* ✅ Linux with `initramfs-tools` (e.g. Debian, Ubuntu, Proxmox, TrueNAS SCALE)
* ✅ ZFS `boot-pool` or `rpool` (used to auto-detect boot drives)
* ✅ Scripts from this repo:

  * `gen-vfio-ids.sh`: Detects and excludes boot drives, lists passthrough-safe devices
  * `vfio-pci-bind`: Initramfs hook that binds PCI devices to `vfio-pci`

---

## 🪪 Step 1: Generate Passthrough PCI Device List (do on currently running machine and whn you shut down remeber to remove all disks except boot-pool disks)

Run the generator:

```bash
bash ./generate-vfio-ids.sh
```

### 📋 Sample Output

```bash
🔍 Detecting boot pool NVMe devices...
🚫 Boot PCI IDs to exclude:
  83:00.0 - 83:00.0 Non-Volatile memory controller [0108]: Kingston Technology Company, Inc. DC2000B NVMe SSD [E18DC] [2646:5024] (rev 01)
  84:00.0 - 84:00.0 Non-Volatile memory controller [0108]: Kingston Technology Company, Inc. DC2000B NVMe SSD [E18DC] [2646:5024] (rev 01)

⚠️  Skipping boot device at 83:00.0 - 83:00.0 Non-Volatile memory controller  (rev 01)
⚠️  Skipping boot device at 84:00.0 - 84:00.0 Non-Volatile memory controller  (rev 01)
✅ Devices to passthrough:
PCI ID     Vendor:Device  Device Description                                          
--------------------------------------------------------------------------------------------
05:00.0    1cc1:8201      ADATA Technology Co., Ltd. XPG SX8200 Pro PCIe Gen3x4 M.2 22
06:00.0    2646:5024      Kingston Technology Company, Inc. DC2000B NVMe SSD  
...

🧹 Paste the following block into your initramfs vfio-pci-bind hook:

BIND_PCI_IDS="
0000:05:00.0
0000:06:00.0
..."
```

Copy that `BIND_PCI_IDS="..."` block for use in the next step.

---

## 🛠 Step 2: Install VFIO Initramfs Hook (done after install of new OS and before you plug in hardware, and if PCIE IDs change you are screwed, rofl)

Create the initramfs hook:

```bash
nano /etc/initramfs-tools/scripts/init-top/vfio-pci-bind
```

Paste the following **and insert your copied `BIND_PCI_IDS` block**:

```sh
#!/bin/sh
PREREQ=""
prereqs() { echo "$PREREQ"; }

case "$1" in
  prereqs) prereqs; exit 0 ;;
esac

. /scripts/functions
echo "🔐 Early vfio-pci binding (initramfs)"

BIND_PCI_IDS="
0000:05:00.0
0000:06:00.0
..."

for id in $BIND_PCI_IDS; do
  echo vfio-pci > /sys/bus/pci/devices/$id/driver_override 2>/dev/null || true
done

modprobe -i vfio-pci
```

Make it executable:

```bash
chmod +x /etc/initramfs-tools/scripts/init-top/vfio-pci-bind
```

---

## 📦 Step 3: Include VFIO Modules in Initramfs

Edit:

```bash
nano /etc/initramfs-tools/modules
```

Add the following lines if not already present:

```bash
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
```

---

## 🔄 Step 4: Rebuild Initramfs

```bash
update-initramfs -u
```

---

## 🚀 Step 5: Reboot & Verify

After reboot, check that passthrough devices are bound to `vfio-pci`:

```bash
lspci -nnk | grep -A2 'Non-Volatile memory\|SATA controller'
```

✅ You should see:

```bash
Kernel driver in use: vfio-pci
```

---

## 🔁 Updating Passthrough Devices

To change which devices are passed through:

1. Re-run `gen-vfio-ids.sh`
2. Update `/etc/initramfs-tools/scripts/init-top/vfio-pci-bind` with new IDs
3. Rebuild initramfs:

   ```bash
   sudo update-initramfs -u
   ```

---

## 🧹 Safety Notes

* Boot devices are **automatically excluded** based on ZFS `boot-pool` or `rpool` membership, no other file systems are automatically detected
* Only NVMe and SATA PCI devices are matched by default
* This setup avoids any interference from systemd or kernel drivers by binding in **initramfs stage** and ensure proxmox ZFS doesn't enumerate pools, which is does on every pool that has been passed through as PCI withou blacklisting the device ID

---

## 📁 Files Overview

| File              | Purpose                                             |
| ----------------- | --------------------------------------------------- |
| `gen-vfio-ids.sh` | Detects passthrough-safe PCI devices                |
| `vfio-pci-bind`   | Binds devices to `vfio-pci` driver during initramfs |

---

## 📘 License

MIT License. Contributions welcome.
