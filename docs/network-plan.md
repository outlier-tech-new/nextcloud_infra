# NAS Network Configuration Plan

Goal: enable both 2.5 GbE interfaces on each NAS as a bonded link connected to the Keeplink KP-9000-6XHML-X2 switch, which only exposes static trunk groups. We will use Linux bonding mode `balance-xor` (static aggregation) for compatibility.

---

## Switch Configuration (Keeplink KP-9000-6XHML-X2)

1. Log in to the switch web UI at `https://192.168.1.168`.
2. Navigate to the **Trunk Group** page.
3. Create two trunks:
   - **Trunk 1**: ports 1 and 2 (office NAS).
   - **Trunk 2**: ports 3 and 4 (house NAS).
4. Leave other port settings (Flow Control, Jumbo Frames, etc.) at defaults unless you need specific features.
5. Save/apply and reboot the switch if prompted.

---

## Office NAS (ubnsvrnas001) Configuration

Assumes network interfaces are `enp3s0` and `enp4s0`. Confirm with `ip link`.

1. Create a netplan file `/etc/netplan/01-bonding.yaml` with the following content:

   ```yaml
   network:
     version: 2
     renderer: networkd
     ethernets:
       enp3s0: {dhcp4: no, dhcp6: no}
       enp4s0: {dhcp4: no, dhcp6: no}
     bonds:
       bond0:
         interfaces: [enp3s0, enp4s0]
         parameters:
           mode: balance-xor
           xmit-hash-policy: layer3+4
           mii-monitor-interval: 100
         addresses:
           - 192.168.1.50/24
         gateway4: 192.168.1.1
         nameservers:
           addresses:
             - 192.168.1.5
             - 1.1.1.1
   ```

   Adjust the static IP (`192.168.1.50`) and nameserver list to suit your network.

2. Apply the configuration:
   ```bash
   sudo netplan apply
   ```
3. Verify:
   ```bash
   ip addr show bond0
   cat /proc/net/bonding/bond0
   ping -c 4 192.168.1.1
   ```
   Output should show both slaves up and mode `balance-xor`.

---

## House NAS Configuration

Repeat the steps above with the second NAS interfaces (likely also `enp3s0`/`enp4s0`). Use a different static IP (e.g. `192.168.1.51/24`). Ensure the switch trunk uses ports 3 and 4.

---

## Notes & Testing

- `balance-xor` provides static link aggregation with load distribution based on layer3+4 hashing. No switch-side LACP is required.
- If you want to test LACP later, change `mode: 802.3ad` and enable LACP on the switch, but revert if the links drop.
- To verify throughput, use `iperf3` or large file copies from another 2.5 GbE host.
- Update DNS records for both NAS hostnames to the new static IPs and update `/srv/nextcloud/nextcloud.env` trusted domains.

