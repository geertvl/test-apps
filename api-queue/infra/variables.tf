## Provider variables (see powershell script create-spn-terraform.ps1)
variable "client_id" {
  description = "This is the same as the appId"
  type        = string
}

variable "client_secret" {
  description = "This is the same as password"
  type        = string
}

variable "tenant_id" {
  description = "This is the same as tenant"
  type        = string
}

# Check the available subscriptions with:
#   az account show --output table
# Set correct subscription with:
#   az account set --subscription "your-subscription-id"
variable "subscription_id" {
  description = "Set the id from the commands in the comment above"
  type        = string
}
