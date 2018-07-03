param
(
    [Parameter (Mandatory = $false)]
    [object] $WebhookData
)

$ErrorActionPreference = "stop"

# If runbook was called from Webhook, WebhookData will not be null.
if ($WebhookData) {

    $action = (ConvertFrom-Json -InputObject $WebhookData.RequestBody)

    $connectionName = "AzureRunAsConnection"
    try {
        # Get the connection "AzureRunAsConnection "
        $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

        "Logging in to Azure..."
        Connect-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
    } catch {
        if (!$servicePrincipalConnection){
            $ErrorMessage = "Connection $connectionName not found."
            throw $ErrorMessage
        } else{
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }

    Write-Output $action.data.resourceUri

    $targetResource = Get-AzureRmResource -ResourceId $action.data.resourceUri
    $name = $action.data.claims.name

    if ($targetResource -eq $null){
        throw "Could not get the detailed of resource"
    }

    $newTag = @{}
    if ($targetResource.Tags -eq $null ){
        Write-Output "Tag is nothing"
        $newTag += @{createdby=$name}
        Set-AzureRmResource -ResourceId $action.data.resourceUri -Tag $newTag -force
        Write-Output "Added 'createdby' tag"
    } else {
        if ($targetResource.Tags.ContainsKey("createdby") -eq $false){
            Write-Output $action.data.resourceUri
            Write-Output "'createdby' tag don't exist"
            if ( $targetResource.Tags ){
                $newTag = $targetResource.Tags
            }
            $newTag += @{createdby=$name}
            Set-AzureRmResource -ResourceId  $action.data.resourceUri -Tag $newTag -force
            Write-Output "Added 'createdby' tag"
        } else {
            Write-Output $action.data.resourceUri
            Write-Output "This resouce Already has 'createdby' tag"
        }
    } 
}
