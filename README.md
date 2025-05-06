# 🛡️ VFIO PCI Passthrough Setup for NVMe & SATA Devices (Boot-Safe)

This repo helps safely bind selected PCI storage devices (NVMe, SATA) to `vfio-pci` **early in boot**, before the kernel or systemd services can claim them — ideal for PCI passthrough to VMs or containers.

---

## 🧰 Requirements

* ✅ Linux with `initramfs-tools` (e.g. Debian, Ubuntu, Proxmox, TrueNAS SCALE)
* ✅ ZFS `boot-pool` (used to auto-detect boot drives)
* ✅ Scripts from this repo:

  * `gen-vfio-ids.sh`: Detects and excludes boot drives, lists passthrough-safe devices
  * `vfio-pci-bind`: Initramfs hook that binds PCI devices to `vfio-pci`

---

## 🪪 Step 1: Generate Passthrough PCI Device List (do on currently running machine and whn you shut down remeber to remove all disks except boot-pool disks)

Run the generator:

```bash
sudo bash ./gen-vfio-ids.sh
```

### 📋 Sample Output

```bash
🔍 Detecting boot pool NVMe devices...
🚫 Boot PCI IDs to exclude: 84:00.0 83:00.0

⚠️ Skipping boot device at 83:00.0
⚠️ Skipping boot device at 84:00.0
✅ Devices to passthrough:
PCI ID     Vendor:Device  Device Description
------------------------------------------------------------
05:00.0    1cc1:8201      ADATA XPG SX8200 Pro
06:00.0    2646:5024      Kingston DC2000B NVMe SSD
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
sudo nano /etc/initramfs-tools/scripts/init-top/vfio-pci-bind
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
sudo chmod +x /etc/initramfs-tools/scripts/init-top/vfio-pci-bind
```

---

## 📦 Step 3: Include VFIO Modules in Initramfs

Edit:

```bash
sudo nano /etc/initramfs-tools/modules
```

Add the following lines if not already present:

```bash
vfio
vfio_pci
```

---

## 🔄 Step 4: Rebuild Initramfs

```bash
sudo update-initramfs -u
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

* Boot devices are **automatically excluded** based on ZFS `boot-pool` membership
* Only NVMe and SATA PCI devices are matched by default
* This setup avoids any interference from systemd or kernel drivers by binding in **initramfs stage**

---

## 📁 Files Overview

| File              | Purpose                                             |
| ----------------- | --------------------------------------------------- |
| `gen-vfio-ids.sh` | Detects passthrough-safe PCI devices                |
| `vfio-pci-bind`   | Binds devices to `vfio-pci` driver during initramfs |

---

## 📘 License

MIT License. Contributions welcome.
