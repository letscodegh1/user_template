# Instrukcja dla kursanta — Terraform + Claude Code na Azure

Masz własną, odizolowaną piaskownicę w Azure: jedną grupę zasobów (resource group) i tożsamość,
która ma prawo tworzyć zasoby **wyłącznie** w tej grupie. Poniżej krok po kroku, jak zacząć.

## 1. Czego potrzebujesz

- `terraform` >= 1.6
- `az` (Azure CLI)
- `claude` (Claude Code)
- `jq`
- powłoka bash (macOS/Linux od razu, na Windowsie: WSL albo Git Bash)

## 2. Co dostajesz od prowadzącego

Jeden plik `studentNN.env` (np. `student03.env`) — Twoje dane logowania. Zawiera sekret,
więc traktuj go jak hasło: nie wysyłaj dalej, nie wklejaj do czatów ani do kodu.

## 3. Pierwsze uruchomienie

```bash
# 1. Schowaj plik z danymi logowania poza katalogiem roboczym
mkdir -p ~/.tf-training
mv student03.env ~/.tf-training/          # podmień na swój numer

# 2. Skopiuj szablon do swojego katalogu roboczego
cp -R student-template ~/tf-lab
cd ~/tf-lab

# 3. Wczytaj dane logowania do bieżącej sesji terminala
source ~/.tf-training/student03.env

# 4. (opcjonalnie) zaloguj `az` jako Twoja tożsamość — przydatne do `az resource list` itp.
./scripts/login.sh

# 5. Zainicjuj Terraform
terraform init

# 6. Uruchom Claude Code
claude
```

Krok 3 (`source ...`) musisz powtórzyć w **każdym nowym oknie terminala** — dane logowania
żyją tylko w bieżącej sesji, nigdzie nie są zapisywane na stałe.

Przy pierwszym uruchomieniu `claude` w tym katalogu zaakceptuj dialog zaufania do folderu.
Bez tego Claude Code ignoruje uprawnienia zapisane w `.claude/settings.json` i będzie pytać
o zgodę na każdą pojedynczą komendę.

## 4. Jak wygląda praca z Claude Code

1. Opisz agentowi, co ma zbudować (patrz przykłady od prowadzącego).
2. Agent edytuje pliki `.tf` — po każdej edycji automatycznie odpala się `terraform fmt` i `validate`.
3. Agent puszcza `terraform plan` i pokazuje Ci podsumowanie.
4. **`terraform apply` wymaga Twojej zgody** — agent nie może go uruchomić z `-auto-approve`,
   sam zatwierdzasz `yes` w terminalu.
5. Sprawdź efekt: `terraform output`, `az resource list -g $TF_VAR_resource_group_name -o table`.
6. Na koniec ćwiczenia posprzątaj: `terraform destroy` (też zatwierdzasz sam).

## 5. Zasady piaskownicy — czego nie da się przeskoczyć

- Twoja grupa zasobów **już istnieje** — nie twórz jej, tylko odwołuj się do niej (`data`, nie `resource`).
- Wszystko powstaje w regionie `westeurope` — inne regiony blokuje polityka Azure.
- Maszyny wirtualne: tylko rozmiar `Standard_B1s`, **1 VM naraz**. Zanim postawisz kolejną,
  zrób `terraform destroy` na poprzedniej (limit CPU w regionie jest wspólny dla wszystkich kursantów).
- Zakazane (polityka Azure odrzuci `apply` mimo że `plan` przejdzie): Azure Firewall, Bastion,
  VPN/ExpressRoute Gateway, Application Gateway, NAT Gateway, AKS, Databricks, Synapse,
  Cosmos DB, Cognitive Services, Front Door/CDN i kilka innych drogich usług.
- Nazwy, które muszą być globalnie unikalne (storage account, Key Vault...), potrzebują losowego
  sufiksu — użyj `random_string`.
- Nie próbuj obchodzić uprawnień ani polityk. Jeśli dostaniesz `AuthorizationFailed` albo
  `RequestDisallowedByPolicy` — to twarda granica piaskownicy, nie błąd do "przechytrzenia".
  Poproś agenta o tańszą/mniejszą alternatywę albo zapytaj prowadzącego.

## 6. Typowe błędy

| Błąd | Co to znaczy |
|---|---|
| `AuthorizationFailed` | Próbujesz coś zrobić poza swoją grupą zasobów albo na uprawnieniu, którego nie masz. |
| `RequestDisallowedByPolicy` | Zasób jest zakazany albo region/SKU się nie zgadza — zobacz sekcję 5. |
| `QuotaExceeded` / brak dostępnego SKU | Masz już uruchomioną 1 VM — zrób najpierw `destroy`. |
| `AADSTS7000215` przy `az login` | Twój sekret wygasł (ważny 7 dni od wygenerowania) — zgłoś się do prowadzącego po nowy plik `.env`. |
| Claude pyta o zgodę na `terraform plan` mimo `permissions.allow` | Nie zaakceptowałeś/aś dialogu zaufania do katalogu przy pierwszym `claude` — patrz koniec sekcji 3. |

## 7. Na koniec szkolenia

```bash
terraform destroy
```

Posprzątaj wszystko, co stworzyłeś/aś, zanim skończysz. Prowadzący i tak usunie całą piaskownicę
po zajęciach, ale dobra praktyka to sprzątanie po sobie.
