provider "azurerm" {
}

data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

resource "random_string" "autotagging" {
  length = 32
}

resource "random_integer" "random" {
  min     = 1
  max     = 999999
}

resource "azuread_application" "autotagging" {
  name                       = "autotagging-${replace(data.azurerm_subscription.current.id,"/.subscriptions.(.*)$/","$1")}"
  homepage                   = "https://autotagging"
}

resource "azuread_service_principal" "autotagging" {
  application_id = "${azuread_application.autotagging.application_id}"
}

resource "azuread_service_principal_password" "autotagging" {
  service_principal_id = "${azuread_service_principal.autotagging.id}"
  value                = "${random_string.autotagging.result}"
  end_date             = "2100-01-01T01:02:03Z"
}

output "spn_password" {
  value = "${random_string.autotagging.result}"
}

resource "azurerm_role_assignment" "autotagging" {
  scope                = "${data.azurerm_subscription.current.id}"
  role_definition_name = "Contributor"
  principal_id         = "${azuread_service_principal.autotagging.id}"
}

resource "azurerm_resource_group" "autotagging" {
  name     = "autotagging-${random_integer.random.result}"
  location = "West US2"
}

resource "azurerm_log_analytics_workspace" "autotagging" {
  name                = "autotagging-${random_integer.random.result}"
  location            = "${azurerm_resource_group.autotagging.location}"
  resource_group_name = "${azurerm_resource_group.autotagging.name}"
  #sku                 = "standalone"
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_storage_account" "autotagging" {
  name                     = "antotagging${random_integer.random.result}"
  location                 = "${azurerm_resource_group.autotagging.location}"
  resource_group_name      = "${azurerm_resource_group.autotagging.name}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "autotagging" {
  name                = "antotagging-${random_integer.random.result}"
  location            = "${azurerm_resource_group.autotagging.location}"
  resource_group_name = "${azurerm_resource_group.autotagging.name}"
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_application_insights" "autotagging" {
  name                = "antotagging-${random_integer.random.result}"
  location            = "${azurerm_resource_group.autotagging.location}"
  resource_group_name = "${azurerm_resource_group.autotagging.name}"
  application_type    = "Web"
}

resource "azurerm_function_app" "autotagging" {
  name                      = "antotagging-${random_integer.random.result}"
  location                  = "${azurerm_resource_group.autotagging.location}"
  resource_group_name       = "${azurerm_resource_group.autotagging.name}"
  app_service_plan_id       = "${azurerm_app_service_plan.autotagging.id}"
  storage_connection_string = "${azurerm_storage_account.autotagging.primary_connection_string}"
  version                   = "~1"
  app_settings {
    "spn_appid"    = "${azuread_application.autotagging.application_id}"
    "spn_tenant"   = "${data.azurerm_client_config.current.tenant_id}"
    "spn_password" = "${random_string.autotagging.result}"
    "workspaceId"  = "${azurerm_log_analytics_workspace.autotagging.workspace_id}"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = "${azurerm_application_insights.autotagging.instrumentation_key}"
  }

}



resource "null_resource" "createZip" {
  provisioner "local-exec" {
    command = "zip -r autotagging.zip autotagging/ host.json"
  }
}

resource "null_resource" "uploadZip" {
  provisioner "local-exec" {
    command = "az functionapp deployment source config-zip -g ${azurerm_resource_group.autotagging.name} -n ${azurerm_function_app.autotagging.name} --src autotagging.zip"
  }
}

resource "null_resource" "connectLaAndActivityLog" {
  provisioner "local-exec" {
    command = "az resource create -g ${azurerm_resource_group.autotagging.name} -n autotagging-${random_integer.random.result} --resource-type dataSources --namespace microsoft.operationalinsights/workspaces --is-full-object --parent autotagging-${random_integer.random.result} -p '{\"properties\":{\"LinkedResourceId\":\"${data.azurerm_subscription.current.id}/providers/microsoft.insights/eventtypes/management\"},\"kind\":\"AzureActivityLog\",\"location\":\"${azurerm_resource_group.autotagging.location}\"}' --api-version 2015-11-01-preview"
  }
}

