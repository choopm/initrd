#!/bin/bash

copy_openssh_keys() {
  local osshrsa="/etc/ssh/ssh_host_rsa_key"
  local osshdsa="/etc/ssh/ssh_host_dsa_key"
  local osshecdsa="/etc/ssh/ssh_host_ecdsa_key"

  local dbpre="dropbear_"

  local return_code=1

  if [ -s "$osshrsa" ]; then
      dropbearconvert openssh dropbear $osshrsa ${dbpre}rsa_host_key
      return_code=0
  fi

  if [ -s "$osshdsa" ]; then
      dropbearconvert openssh dropbear $osshdsa ${dbpre}dss_host_key
      return_code=0
  fi

  if [ -s "$osshecdsa" ]; then
      dropbearconvert openssh dropbear $osshecdsa ${dbpre}ecdsa_host_key
      return_code=0
  fi

  return $return_code
}

generate_keys() {
  local keyfile keytype
  for keytype in rsa dss ecdsa ; do
      keyfile="dropbear_${keytype}_host_key"
      if [ ! -s "$keyfile" ]; then
	  echo "Generating ${keytype} host key for dropbear ..."
	  dropbearkey -t "${keytype}" -f "${keyfile}"
      fi
  done
}

clean_keys() {
	for keytype in rsa dss ecdsa ; do
		keyfile="dropbear_${keytype}_host_key"
		if [ -s "$keyfile" ]; then
			rm $keyfile
		fi
	done
}

KEYMAP="de-latin1"

echo "Generating keymap"
loadkeys -b $KEYMAP > keymap

echo "Copying openssh keys"
copy_openssh_keys || generate_keys

cd /usr/src/linux
echo "Creating initrd..."
scripts/gen_initramfs_list.sh -o /boot/initramfs-gentoo /usr/src/initramfs/initramfs_list

cd /usr/src/initramfs
rm keymap
clean_keys
