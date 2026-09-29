---
marp: true
paginate: true
theme: default
size: 16:9
---

# CI/CD jako bramka dla kodu od AI
## Jak weryfikować to, co napisał Claude Code

Szkolenie: Terraform + Claude Code na Azure

---

## Problem: AI pisze szybciej, niż człowiek czyta

- Claude Code potrafi wygenerować dziesiątki linii Terraforma w kilka sekund.
- Kod **wygląda** poprawnie, a i tak bywa zły: zmyślony argument, zły region, zasób, który polityka Azure odrzuci.
- Recenzja „na oko" nie skaluje się z tempem generowania.
- Model nie odpowiada za skutki. Odpowiada za nie człowiek, który kliknął *apply*.

**Wniosek:** zaufanie do AI trzeba zastąpić **mechaniczną weryfikacją**.

---

## Idea: bramka (gate)

Bramka to automatyczny punkt kontrolny, którego kod **nie ominie**, niezależnie od tego, kto go napisał.

```
 AI / człowiek ──► commit ──► PR ──► [ CI gate ] ──► merge ──► [ CD gate ] ──► Azure
                                       maszyna                    człowiek
```

- **Gate maszynowy (CI)** — tani, szybki, deterministyczny. Odsiewa błędy składniowe i formatowanie.
- **Gate ludzki (CD)** — drogi, ale tylko tam, gdzie stawka jest wysoka: zmiana realnej infrastruktury.

AI jest w tym modelu po prostu kolejnym autorem, który przechodzi przez te same bramki.

---

## Warstwy weryfikacji kodu z AI

| Warstwa | Kiedy | Kto | Co łapie |
|---|---|---|---|
| Hook w Claude Code | po każdej edycji | maszyna | `fmt`, `validate` lokalnie |
| CLAUDE.md (zasady) | w trakcie generowania | model | ograniczenia demo |
| **CI** | PR / push do `main` | maszyna | to, co ominięto lokalnie |
| **Plan review** | przed deployem | człowiek | skutki zmiany |
| **CD z zatwierdzeniem** | deploy | człowiek | zgoda na *apply* |
| Polityki Azure | w chmurze | Azure | to, czego nikt wcześniej nie złapał |

Każda warstwa łapie to, co przepuściła poprzednia. Żadna sama nie wystarcza.

---

## Dlaczego nie ufać samemu CLAUDE.md

- `CLAUDE.md` to **prośba** do modelu, nie mechanizm wymuszający.
- Model może zignorować instrukcję, źle ją zinterpretować albo o niej „zapomnieć" w długiej sesji.
- CI działa **poza** modelem: nie da się go przekonać ani zagadać.

> Instrukcje kierują AI. Bramki egzekwują wynik.

W naszym szablonie oba działają razem: `CLAUDE.md` zmniejsza liczbę błędów, CI gwarantuje, że reszta nie przejdzie.

---

## Nasz pipeline: dwa pliki

```
student-template/.github/workflows/
├── ci.yaml    # Terraform check  — automatycznie
└── cd.yaml    # Terraform deploy — ręcznie + zgoda
```

- `ci.yaml` → uruchamia się sam przy każdym PR i pushu do `main`.
- `cd.yaml` → uruchamia się **tylko ręcznie** (`workflow_dispatch`) i wymaga zatwierdzenia.

Rozdzielenie CI od CD to podstawa: sprawdzanie jest tanie i bezpieczne, wdrażanie nie.

---

## Bramka 1: CI (`ci.yaml`)

```yaml
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

permissions:
  contents: read
```

```yaml
- run: terraform fmt -check -recursive -diff
- run: terraform init -backend=false -input=false
- run: terraform validate
```

- **Bez poświadczeń Azure** — CI nie potrzebuje sekretów, więc kod z PR nie ma do nich dostępu.
- `-backend=false` — żadnego dotykania stanu.
- `permissions: contents: read` — najmniejsze możliwe uprawnienia.

---

## Co CI łapie, a czego nie

**Łapie:**
- niesformatowany kod (`fmt`),
- błędy składni HCL,
- nieistniejące zasoby i argumenty, złe typy, brakujące zmienne (`validate`).

**Nie łapie:**
- czy zmiana jest **sensowna** biznesowo,
- co realnie zostanie utworzone lub **usunięte** w Azure,
- czy polityka Azure ją odrzuci,
- kosztów.

Zielone CI znaczy „kod jest poprawny składniowo", a **nie** „zmiana jest bezpieczna".
Do reszty potrzebujemy planu.

---

## Bramka 2: plan jako dowód (`cd.yaml`, job `plan`)

```yaml
- run: terraform plan -input=false -no-color -out=tfplan
- name: Plan summary
  run: |
    echo '### terraform plan'      >> "$GITHUB_STEP_SUMMARY"
    terraform show -no-color tfplan >> "$GITHUB_STEP_SUMMARY"
- uses: actions/upload-artifact@v4
  with: { name: tfplan, path: tfplan }
```

- Plan pokazuje **dokładnie** co się zmieni: `+ create`, `~ update`, `- destroy`.
- Trafia do podsumowania joba, więc recenzent widzi go bez logowania do Azure.
- Plan zapisany do pliku (`-out=tfplan`) staje się **artefaktem**, który potem zostanie zastosowany.

---

## Bramka 3: zatwierdzenie przez człowieka

```yaml
apply:
  needs: plan
  environment: production      # <- tu działa bramka
  concurrency:
    group: terraform-apply
    cancel-in-progress: false
```

- `environment: production` + **Required reviewers** (Settings → Environments) wstrzymuje job do czasu kliknięcia *Approve*.
- `needs: plan` — apply nie ruszy bez udanego planu.
- `concurrency` — dwa apply naraz nie zniszczą stanu.

**Człowiek zatwierdza plan, nie kod.** Tylko człowiek zna kontekst, którego model nie ma.

---

## Kluczowy detal: apply stosuje *ten sam* plan

```yaml
- uses: actions/download-artifact@v4
  with: { name: tfplan }
- run: terraform apply -input=false tfplan
```

- Recenzent oglądał konkretny plan → apply wykonuje **dokładnie ten** plik.
- Nie ma okna, w którym kod zmieni się między zatwierdzeniem a wdrożeniem.
- Bez tego „zatwierdziłem plan A, wdrożyło się B" jest realnym scenariuszem.

To odpowiednik `terraform apply` **bez** `-auto-approve` z `CLAUDE.md`, tylko wymuszony przez system.

---

## Sekrety i najmniejsze uprawnienia

```yaml
env:
  ARM_CLIENT_ID:       ${{ secrets.ARM_CLIENT_ID }}
  ARM_CLIENT_SECRET:   ${{ secrets.ARM_CLIENT_SECRET }}
  TF_VAR_resource_group_name: ${{ vars.TF_VAR_RESOURCE_GROUP_NAME }}
```

- Sekrety tylko w **CD**, nigdy w CI dla PR.
- Tożsamość ma rolę **Contributor tylko na jednej RG**. Nawet zły plan nie wyjdzie poza demo.
- Nazwa RG i region to zwykłe *variables*, nie sekrety.
- Model nie widzi sekretów z GitHuba i nie może ich wypisać.

**Bramki + wąskie uprawnienia = ograniczony promień rażenia.**

---

## Scenariusz: AI się myli

Prosimy Claude o storage account, a on:

1. wpisuje region `northeurope` na sztywno → **polityka Azure** odrzuci (dozwolony tylko `westeurope`),
2. zmienia `resource_provider_registrations` → łamie `CLAUDE.md`,
3. dodaje Azure Firewall → `RequestDisallowedByPolicy`.

| Błąd | Kto zatrzyma |
|---|---|
| zły format / składnia | hook lokalnie, potem **CI** |
| literówka w argumencie | `terraform validate` w **CI** |
| niechciany `destroy` w planie | **recenzent** przy zatwierdzeniu |
| zakazana usługa lub region | **polityka Azure** (ostatnia linia obrony) |

---

## Zasady dobrej bramki

1. **Deterministyczna** — ten sam kod, ten sam wynik. Nie „LLM ocenia LLM-a".
2. **Nie do obejścia** — wymuszona przez system (branch protection), nie przez konwencję.
3. **Szybka** — CI w sekundach, inaczej ludzie zaczną ją omijać.
4. **Czytelna** — plan w podsumowaniu, nie w 2000 linii logów.
5. **Wąskie uprawnienia** — bramka działa tylko wtedy, gdy za nią nie ma otwartych drzwi.
6. **Człowiek tam, gdzie stawka** — nie wszędzie, bo zmęczony recenzent klika *Approve* bez czytania.

---

## Jak to włączyć w repozytorium

1. Wgraj kod z `.github/workflows/` do repo na GitHubie.
2. **Settings → Secrets and variables → Actions:**
   secrets `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`,
   variables `TF_VAR_RESOURCE_GROUP_NAME`, `TF_VAR_LOCATION`.
3. **Settings → Environments → New → `production`** → *Required reviewers*.
4. **Settings → Branches → Branch protection** dla `main`: wymagaj przejścia checku *fmt + validate* i PR.
5. Uruchom: **Actions → Terraform deploy → Run workflow**, obejrzyj plan, zatwierdź.

---

## Ćwiczenie

1. Poproś Claude Code o drobną zmianę w `network.tf`.
2. Celowo zepsuj formatowanie lub wpisz nieistniejący argument → otwórz PR → **zobacz, jak CI go zatrzymuje**.
3. Popraw, zmerguj, odpal *Terraform deploy*.
4. Przeczytaj plan w podsumowaniu: czy jest tam coś, czego nie prosiłeś? Jakieś `destroy`?
5. Zatwierdź albo odrzuć — i uzasadnij decyzję.

**Pytanie do dyskusji:** co jeszcze dodałbyś do CI? (`tflint`, `checkov`, `infracost`, skan sekretów?)

---

## Podsumowanie

- AI to szybki autor, który się myli. Nie jest recenzentem własnej pracy.
- **CI** odsiewa tanie błędy maszynowo, **plan + zatwierdzenie** oddaje decyzję człowiekowi.
- Apply stosuje **zatwierdzony plan**, a nie „aktualny kod".
- Wąskie uprawnienia i polityki Azure to sieć bezpieczeństwa za bramkami.
- `CLAUDE.md` kieruje modelem, **bramki egzekwują wynik**.

> Nie pytaj „czy AI napisało dobrze?". Zbuduj system, w którym zły kod się nie przedostanie.
