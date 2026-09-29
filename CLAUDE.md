# Piaskownica Terraform na Azure (szkolenie)

Pracujesz w ograniczonej piaskownicy. Masz uprawnienia Contributor **tylko** na jednej,
już istniejącej grupie zasobów. Poświadczenia i nazwa RG są w zmiennych środowiskowych
(`ARM_*`, `TF_VAR_resource_group_name`, `TF_VAR_location`), więc nigdy ich nie wypisuj i nie
zapisuj do plików.

## Zasady

- Grupa zasobów **już istnieje**. Używaj `data "azurerm_resource_group" "main"`, nigdy `resource`.
- Wszystkie zasoby tworzysz w tej RG i w regionie z `var.location`. Nie wpisuj regionu na sztywno.
- Tagi bierz z RG: `tags = data.azurerm_resource_group.main.tags`.
- Nie zmieniaj `resource_provider_registrations = "none"` w `providers.tf`. Providery są zarejestrowane
  przez prowadzącego, a Twoja tożsamość nie ma do tego uprawnień.
- Dozwolone rozmiary VM: tylko `Standard_B1s` (1 vCPU). Limit vCPU na region dla całej subskrypcji to 10,
  więc **maksymalnie 1 VM na kursanta jednocześnie** — usuń poprzednią VM (`terraform destroy`), zanim stawiasz kolejną.
- Zakazane (polityka Azure zablokuje): Azure Firewall, Bastion, VPN/ExpressRoute Gateway, Application Gateway,
  NAT Gateway, AKS, Databricks, Synapse, Cosmos DB, Cognitive Services, Front Door/CDN.
- Nazwy storage account, Key Vault itp. muszą być globalnie unikalne. Dodaj losowy sufiks (`random_string`).
- Nie próbuj obchodzić uprawnień ani polityk. Przy `AuthorizationFailed` albo `RequestDisallowedByPolicy`
  zaproponuj tańsze lub mniejsze rozwiązanie albo powiedz użytkownikowi, że to blokada piaskownicy.

## Sposób pracy

1. Zmień kod (`main.tf`, `variables.tf`, `outputs.tf`). Po każdej edycji hook uruchamia `fmt` i `validate`.
2. `terraform plan` (albo `/plan-review`, żeby dostać recenzję planu).
3. Pokaż użytkownikowi krótkie podsumowanie planu i poproś o zgodę.
4. `terraform apply` **bez** `-auto-approve`. Użytkownik zatwierdza go sam.
5. Zweryfikuj wynik (`terraform output`, `az resource list -g $TF_VAR_resource_group_name -o table`).
6. Na koniec ćwiczenia posprzątaj: `terraform destroy` (też za zgodą użytkownika).

Odpowiadaj po polsku, zwięźle.
