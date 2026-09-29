#!/usr/bin/env bash
# PreToolUse (Bash): blokuje `terraform apply|destroy` z flagą -auto-approve.
# Exit 2 = blokada wywołania, a stderr wraca do Claude'a jako powód.
# Celowo bez jq: to hook bezpieczeństwa i nie powinien przestać działać po cichu.

input=$(cat)

if grep -Eq 'terraform[[:space:]]+(apply|destroy)' <<<"$input" &&
  grep -Eq -e '-auto-approve' <<<"$input"; then
  echo "Zablokowano: apply/destroy z -auto-approve jest niedozwolone na szkoleniu. Uruchom to samo polecenie bez tej flagi, a użytkownik zatwierdzi je sam." >&2
  exit 2
fi

exit 0
