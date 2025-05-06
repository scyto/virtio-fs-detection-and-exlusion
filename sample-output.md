# sample output

```bash
🔍 Detecting boot pool NVMe devices...
🚫 Boot PCI IDs to exclude:
  84:00.0 - 84:00.0 Non-Volatile memory controller  (rev 01)
  83:00.0 - 83:00.0 Non-Volatile memory controller  (rev 01)

⚠️  Skipping boot device at 83:00.0 - 83:00.0 Non-Volatile memory controller  (rev 01)
⚠️  Skipping boot device at 84:00.0 - 84:00.0 Non-Volatile memory controller  (rev 01)
✅ Devices to passthrough:
PCI ID     Vendor:Device  Device Description                                          
--------------------------------------------------------------------------------------------
05:00.0    1cc1:8201      ADATA Technology Co., Ltd. XPG SX8200 Pro PCIe Gen3x4 M.2 22
06:00.0    2646:5024      Kingston Technology Company, Inc. DC2000B NVMe SSD          
07:00.0    2646:5024      Kingston Technology Company, Inc. DC2000B NVMe SSD          
42:00.0    1022:7901      Advanced Micro Devices, Inc.  (AMD SATA Controller)         
42:00.1    1022:7901      Advanced Micro Devices, Inc.  (AMD SATA Controller)         
a1:00.0    8086:2700      Intel Corporation 900P Series                               
a3:00.0    8086:2700      Intel Corporation 900P Series                               
a5:00.0    8086:2700      Intel Corporation 900P Series                               
a7:00.0    8086:2700      Intel Corporation 900P Series                               
e1:00.0    1bb1:5018      Seagate Technology PLC E18 PCIe SSD                         
e2:00.0    1bb1:5018      Seagate Technology PLC E18 PCIe SSD                         
e3:00.0    1bb1:5018      Seagate Technology PLC E18 PCIe SSD                         
e4:00.0    1bb1:5018      Seagate Technology PLC E18 PCIe SSD                         
e6:00.0    1022:7901      Advanced Micro Devices, Inc.  (AMD SATA Controller)         
e6:00.1    1022:7901      Advanced Micro Devices, Inc.  (AMD SATA Controller)         

🧩 Paste the following block into your initramfs vfio-pci-bind hook:

BIND_PCI_IDS="
0000:05:00.0
0000:06:00.0
0000:07:00.0
0000:42:00.0
0000:42:00.1
0000:a1:00.0
0000:a3:00.0
0000:a5:00.0
0000:a7:00.0
0000:e1:00.0
0000:e2:00.0
0000:e3:00.0
0000:e4:00.0
0000:e6:00.0
0000:e6:00.1
"
```
