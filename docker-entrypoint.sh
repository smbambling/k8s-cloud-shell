#!/bin/bash
set -e

if [[ -n "${AGE_KEY}" && -f "${AGE_KEY//\"}" ]]; then
  if [[ -n "${AGE_KEY_PASSPHRASE}" ]]; then
    mkdir -p /root/.config/sops/age
    expect <<- DONE > /dev/null 2>&1
      set timeout -1
      spawn age -o /root/.config/sops/age/keys.txt -d "${AGE_KEY//\"}"
      match_max 100000
      expect -exact "Enter passphrase: "
      send -- "${AGE_KEY_PASSPHRASE//\"}\r"
      expect eof
DONE
    if grep -q "AGE-SECRET-KEY" /root/.config/sops/age/keys.txt > /dev/null 2>&1; then
      echo -e "Decrypted age keypair: ${AGE_KEY}\n"
    else
      echo -e "Failed to decrypt age keypair: ${AGE_KEY}\n"
      exit 1
    fi
  fi
fi

exec "$@"
