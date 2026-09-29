variable "resource_group_name" {
  description = "Istniejąca RG kursanta (ustawiana przez TF_VAR_resource_group_name)."
  type        = string
}

variable "location" {
  description = "Region piaskownicy (ustawiany przez TF_VAR_location)."
  type        = string
  default     = "westeurope"
}
