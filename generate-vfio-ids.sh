#!/bin/bash
set -euo pipefail

echo "🔍 Detecting boot pool NVMe devices..."

BOOT_PCI_IDS=()
if command -v zpool &>/dev/null; then
  while IFS= read -r partdev; do
    basedev=$(basename "$partdev" | sed -E 's/p[0-9]+$//')
    pci_path=$(readlink -f /sys/block/$basedev/device 2>/dev/null || true)
    if [[ -n "$pci_path" ]]; then
      pci_addr=$(basename "$(dirname "$(dirname "$pci_path")")")
      pci_addr=${pci_addr#0000:}
      BOOT_PCI_IDS+=("$pci_addr")
    fi
  done < <(sudo zpool status boot-pool 2>/dev/null | awk '/boot-pool/ {f=1; next} f && /nvme/ {print $1}')
else
  echo "⚠️  zpool not found — skipping boot device detection"
fi

echo "🚫 Boot PCI IDs to exclude:"
for pci_id in "${BOOT_PCI_IDS[@]}"; do
  # Use lspci to get the full vendor and device description
  device_info=$(lspci -s "$pci_id" -nn | sed -E 's/^[^ ]+ +[^ ]+ +//')
  echo "  $pci_id - $device_info"
done
echo ""

VFIO_IDS=()
MATCHED_DEVICES=()
PASSTHROUGH_PCI_IDS=()

while IFS= read -r line; do
  PCI_ID=$(echo "$line" | awk '{print $1}')
  VENDOR_DEVICE=$(echo "$line" | grep -oP '\[\K[0-9a-f]{4}:[0-9a-f]{4}(?=\])')

  [[ -z "$PCI_ID" || -z "$VENDOR_DEVICE" ]] && continue
  [[ " ${BOOT_PCI_IDS[*]} " =~ " $PCI_ID " ]] && {
    device_info=$(lspci -s "$PCI_ID" -nn | sed 's/\[.*\]//')
    echo "⚠️  Skipping boot device at $PCI_ID - $device_info"
    continue
  }

  VERBOSE_DESC=$(lspci -s "$PCI_ID" -v | grep -m1 "Subsystem:" | sed 's/.*Subsystem: //')
  VERBOSE_DESC=${VERBOSE_DESC:-$(echo "$line" | cut -d' ' -f2-)}
  VERBOSE_DESC=$(echo "$VERBOSE_DESC" | sed 's/\[.*\]//' | cut -c1-60)

  # Add a label for AMD SATA controllers
  if [[ "$VENDOR_DEVICE" == "1022:7901" ]]; then
    VERBOSE_DESC="$VERBOSE_DESC (AMD SATA Controller)"
  fi

  if [[ ! " ${VFIO_IDS[*]} " =~ "$VENDOR_DEVICE" ]]; then
    VFIO_IDS+=("$VENDOR_DEVICE")
  fi

  MATCHED_DEVICES+=("$PCI_ID|$VENDOR_DEVICE|$VERBOSE_DESC")
  PASSTHROUGH_PCI_IDS+=("0000:$PCI_ID")
done < <(lspci -nn | grep -Ei 'Non-Volatile memory controller|SATA controller')

# === Human-friendly output ===
echo "✅ Devices to passthrough:"
printf "%-10s %-14s %-60s\n" "PCI ID" "Vendor:Device" "Device Description"
echo "--------------------------------------------------------------------------------------------"
for entry in "${MATCHED_DEVICES[@]}"; do
  IFS="|" read -r PCI VDEV DESC <<< "$entry"
  printf "%-10s %-14s %-60s\n" "$PCI" "$VDEV" "$DESC"
done

echo ""
echo "🧩 Paste the following block into your initramfs vfio-pci-bind hook:"
echo
echo 'BIND_PCI_IDS="'
for pci in "${PASSTHROUGH_PCI_IDS[@]}"; do
  echo "$pci"
done
echo '"'