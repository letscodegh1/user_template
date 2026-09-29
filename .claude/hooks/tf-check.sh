#!/usr/bin/env bash
# PostToolUse (Edit|Write): po zmianie pliku .tf robi `terraform fmt` i `validate`.
# Przy błędzie zwraca JSON z additionalContext, żeby agent sam poprawił kod.
# (W PostToolUse exit 2 nie jest honorowany, więc wynik idzie przez stdout.)
# Wymaga jq; bez niego hook po prostu nic nie robi.

command -v jq >/dev/null 2>&1 || exit 0

file=$(jq -r '.tool_input.file_path // empty')
[[ "$file" == *.tf ]] || exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

terraform fmt "$file" >/dev/null 2>&1

report() {
  jq -n --arg msg "$1" \
    '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $msg}}'
}

if [[ ! -d .terraform ]]; then
  report "Nie uruchomiono jeszcze 'terraform init', więc nie da się zwalidować zmian w ${file##*/}. Uruchom 'terraform init'."
  exit 0
fi

if ! out=$(terraform validate -no-color 2>&1); then
  report "terraform validate zgłasza błędy po edycji ${file##*/}. Popraw je:
${out}"
fi

exit 0
