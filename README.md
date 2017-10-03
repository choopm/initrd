# initrd
## What is this?
Custom initrd for cryptsetup encrypted rootfs, targeting Gentoo users. Replaces genkernel, dracut and so on..
Core-features: password prompt unlocking, remote (SSH) unlocking, keyfile unlocking

## Installation:
It's assumed you have emerged busybox and dropbear:

`USE="static" emerge -av busybox`

`USE="-pam -syslog -zlib" emerge -av dropbear`

Place all files in `/usr/src/initramfs` and issue `./mkinitrd.sh`.
It will create the keymap of choice, convert your ssh keys (if any) and zip everything together to `/boot/initramfs-gentoo`.

After installation, configure your bootloader. Example for syslinux:
```
LABEL gentoo
    MENU LABEL G^entoo hardened amd64
    LINUX ../vmlinuz-gentoo
    APPEND crypt_root=UUID=<your-uuid>:root:trim root=/dev/mapper/root rootflags=subvol=gentoo net=192.168.1.42/24:192.168.1.1:8.8.8.8:eth0 rw
    INITRD ../initramfs-gentoo
```

## Usage:
If specified, the init will try to use the keyfile to open your luks container (defined by crypt_root=).
If there's no keyfile defined, or it's unavailable (init is waiting 5 seconds for the device), you will be prompted for a password.
In the meantime, you may login via SSH, either by `root:root` or public-key defined in [authorized_keys](authorized_keys) (user:pass configureable or deactivatable by -s in [init](init)).
As soon as the luks containers opens, everything is cleaned up, your specified `root=` is mounted and it's switch_root'ed to.

## Bootloader options
* `root=/dev/sda2` or `root=UUID=<your-uuid>` - The rootfs which should be mounted + switch_root'ed to
* `init=/init` - optional, default in linux kernel
* `real_init=/sbin/init` - optional, what to start when switch_root'ing. Auto-detection for openrc and systemd.
* `rootflags=rw,subvol=snap/backup,noatime` - optional, mount options for your rootfs
* `crypt_root=<blockdev>:<optional dm-name>:<optional trim>` - optional, either a block device or a UUID may be given, second part can be used to specfiy the `/dev/mapper/xyz` name, third argument `trim` allows discards (SSD) to be passed
* `cryptkey=/dev/sdb1:pic/me.png` or `cryptkey=/dev/sdb:2048:4096` - optional, the second variant gets 4096 bytes of sdb, skipping the first 2048 (2049-6145) and uses them as a keyfile
* `net=<cidr>:<gateway>:<dns>:<dev>` - optional, network settings during booting (for SSH remote unlocking)
* `breakinit=y` - optional, if set, drops you to shell after unlocking and mounting the rootfs
