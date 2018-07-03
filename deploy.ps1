$location = "japaneast"
$ErrorActionPreference = "stop"

$subscriptionId = (Get-AzureRmContext).Subscription
$subId = "/subscriptions/" + $subscriptionId
$appName = "autoTagging_$subscriptionId"

Write-Output ((Get-Date -format "yyyy/MM/dd HH:mm:ss") + " Create resource group")
$resourceGroup = New-AzureRmResourceGroup -Name $appName -Location $location

Write-Output ((Get-Date -format "yyyy/MM/dd HH:mm:ss") + " Create event grid")
$eventGrid = New-AzureRmEventGridTopic -ResourceGroupName $resourceGroup.ResourceGroupName -Location $location -Name $appName

Write-Output ((Get-Date -format "yyyy/MM/dd HH:mm:ss") + " Create automation account")
$autoAccount = New-AzureRmAutomationAccount -Name $appName -Location $location -ResourceGroupName $resourceGroup.ResourceGroupName

$autoAccountName = $autoAccount.AutomationAccountName
Write-Output "Please create Run as Account manually for Automation account $autoAccountName"
$input = Read-Host "Did you create Run as Account?(Y/N)"

if ($input -ne "Y"){
    throw "You should create Run as Account"
}

Write-Output "Please update Azure PowerShell module manually for Automation account $autoAccountName"
$input = Read-Host "Did you update Azure PowerShell module?(Y/N)"

if ($input -ne "Y"){
    throw "You should update Azure PowerShell module"
}

Write-Output ((Get-Date -format "yyyy/MM/dd HH:mm:ss") + " import and publish runbook to Automation account $autoAccountName")
$runbook = Import-AzureRmAutomationRunbook -Path .\tagging.ps1 -AutomationAccountName $autoAccountName `
                                           -Type PowerShell -ResourceGroupName $resourceGroup.ResourceGroupName

Publish-AzureRmAutomationRunbook -ResourceGroupName $resourceGroup.ResourceGroupName -AutomationAccountName $autoAccountName -Name $runbook.Name

$Webhook = New-AzureRmAutomationWebhook -Name "fromEventGrid" -IsEnabled $True -ExpiryTime (Get-Date).AddYears(8) `
                                        -RunbookName $runbook.Name -ResourceGroup $resourceGroup.ResourceGroupName `
                                        -AutomationAccountName $autoAccountName -Force

Write-Output ((Get-Date -format "yyyy/MM/dd HH:mm:ss") + " Add event grid subscription")

$eventSub = New-AzureRmEventGridSubscription -ResourceId $subId -EventSubscriptionName $appName `
                                             -EndpointType webhook -Endpoint $webhook.WebhookURI -IncludedEventType "Microsoft.Resources.ResourceWriteSuccess"

Write-Output ((Get-Date -format "yyyy/MM/dd HH:mm:ss") + " Deploy finished")
