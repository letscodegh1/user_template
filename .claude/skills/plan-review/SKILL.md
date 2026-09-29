---
name: plan-review
description: Uruchamia terraform plan i oddaje go do recenzji subagentowi tf-reviewer (zgodność z piaskownicą, koszt, bezpieczeństwo).
disable-model-invocation: true
allowed-tools: Bash(terraform plan) Bash(terraform plan *)
---

## Wynik `terraform plan`

!`terraform plan -no-color -input=false 2>&1 | head -400`

## Instrukcje

1. Jeśli plan zakończył się błędem, wyjaśnij przyczynę i zaproponuj poprawkę. Nie uruchamiaj `apply`.
2. W przeciwnym razie przekaż powyższy plan subagentowi `tf-reviewer` (narzędzie Agent) i pokaż jego werdykt bez skracania.
3. Zakończ jednym zdaniem: bezpieczne do apply albo wymaga poprawek (jakich). Nie uruchamiaj `terraform apply`. Decyzję podejmuje użytkownik.
