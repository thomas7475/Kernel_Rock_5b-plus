#!/bin/bash
# bcachefs DKMS guard, shipped by the kernel packages of this repository
# (see README.md, "Boot safety").
#
# Background: on 2026-11-22 a ROCK 5B+ with a bcachefs root filesystem was
# left unbootable by a kernel update: the bcachefs DKMS module failed to
# build for the new kernel, the initramfs shipped without it, and the next
# reboot ended in an emergency shell with an unmountable root filesystem.
#
# This script runs after pacman transactions that involve the kernel
# package and verifies the bcachefs module exists for every installed
# kernel, printing a loud warning with the fix commands when one is
# missing. It only reports -- it never fails the pacman transaction.

# Nothing to guard if bcachefs is not DKMS-managed on this machine.
command -v dkms >/dev/null 2>&1 || exit 0
dkms status 2>/dev/null | grep -q '^bcachefs/' || exit 0

missing=()
for kdir in /usr/lib/modules/*; do
  [ -d "${kdir}" ] || continue
  # The module is present as a DKMS build, or in-tree (kernels up to 6.17).
  if ! compgen -G "${kdir}/updates/dkms/bcachefs.ko*" >/dev/null \
     && ! compgen -G "${kdir}/kernel/fs/bcachefs/bcachefs.ko*" >/dev/null; then
    missing+=("${kdir##*/}")
  fi
done

if [ "${#missing[@]}" -gt 0 ]; then
  echo
  echo ">>> WARNING: the bcachefs DKMS module is NOT built for:"
  printf '>>>   %s\n' "${missing[@]}"
  echo ">>> If your root filesystem is bcachefs, DO NOT reboot into these"
  echo ">>> kernels. Check and fix:"
  echo ">>>   dkms status                     (installed bcachefs version)"
  echo ">>>   dkms install bcachefs/<version> -k <kernel-version>"
  echo ">>>   mkinitcpio -P"
  echo
fi

exit 0
