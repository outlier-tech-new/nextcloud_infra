# System Inventory

Generated on 2025-11-12.

## Host Overview
- Hostname: ubnsvrnas001
- Operating system: Ubuntu 24.04.3 LTS
- Kernel: Linux 6.8.0-87-generic
- Architecture: x86-64
- Hardware vendor and model: AZW ME mini
- Firmware version and date: M1V404 (2025-08-27)

## CPU
- Model: Intel N150
- Core topology: 4 cores, 1 thread per core
- Base to turbo frequency: 0.7 GHz to 3.6 GHz
- Virtualization support: Intel VT-x available
- Notable ISA extensions: SSE4.2, AVX, AVX2, FMA, AES-NI, SHA

## Memory
- Physical memory: 16 GiB installed
- Swap: 4 GiB configured (unused as of inventory)
- Available memory at capture: ~14 GiB free

## Storage Layout
| Device    | Size   | Role                  | Notes |
|-----------|--------|-----------------------|-------|
| nvme2n1   | 931.5G | System disk (OS)      | EFI (1G), /boot ext4 (2G), remaining 928.5G in LVM; 100G logical volume mounted at `/` |
| nvme0n1   | 3.6T   | Data bay (empty)      | Planned member of ZFS mirror vdev |
| nvme1n1   | 3.6T   | Data bay (empty)      | Planned member of ZFS mirror vdev |

Raw `lsblk` output at capture time:

```
NAME                        SIZE TYPE FSTYPE      MOUNTPOINT
sda                           0B disk             
sr0                        1024M rom              
nvme2n1                   931.5G disk             
├─nvme2n1p1                   1G part vfat        /boot/efi
├─nvme2n1p2                   2G part ext4        /boot
└─nvme2n1p3               928.5G part LVM2_member 
  └─ubuntu--vg-ubuntu--lv   100G lvm  ext4        /
nvme1n1                     3.6T disk             
nvme0n1                     3.6T disk             
```

## Platform Services
- Nextcloud snap: 31.0.10snap1 (channel latest/stable)
- Base snaps: core18 (2959), snapd (2.72)

## Items To Address
- Install ZFS toolchain (`zfsutils-linux`) prior to pool creation.
- Decide on replication tooling (see `storage-replication-plan.md`).
- Configure SMART monitoring and regular `zpool scrub` scheduling once pools exist.
- Verify UPS integration and power protection before production use.
