$ErrorActionPreference = "Stop";
try{

    import-module "D:\home\site\wwwroot\autotagging\azuremodules\AzureRM.Profile\AzureRM.Profile.psd1" -Global
    import-module "D:\home\site\wwwroot\autotagging\azuremodules\AzureRM.OperationalInsights\AzureRM.OperationalInsights.psd1" -Global
    import-module "D:\home\site\wwwroot\autotagging\azuremodules\AzureRM.Resources\AzureRM.Resources.psd1" -Global

    $appId = ls env:spn_appid
    $tenant = ls env:spn_tenant
    $password = ls env:spn_password
    $workspaceId = ls env:workspaceId
    $securePassword = $password.value | ConvertTo-SecureString -AsPlainText -Force
    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $appId.value, $securePassword
    Login-AzureRmAccount -ServicePrincipal `
        -Credential $credential `
        -TenantId $tenant.value

    $query = 'AzureActivity | where ActivitySubstatus contains "Create" | where ResourceProvider != "Microsoft.Authorization" | where ResourceId !contains "providers/Microsoft.Resources/deployments" | project TimeGenerated, Caller, Resource, ResourceProvider,  ResourceId, ActivitySubstatus | sort by TimeGenerated desc'
    # 必ず１時間間隔とは限らないので、多少かぶらせるために65分Spanで
    $queryResults = Invoke-AzureRmOperationalInsightsQuery `
        -WorkspaceId $workspaceId.value `
        -Query $query -Timespan (New-TimeSpan -Minutes 65)

    foreach($item in $queryResults.Results){

        if ($item.ResourceType == "	Microsoft Resources"){
            $resource = Get-AzureRmResourceGroup -ResourceId $item.ResourceId
        } else {
            $resource = Get-AzureRmResource -ResourceId $item.ResourceId -ExpandProperties
        }

        # リソースの情報が取得できて（正しいレスポンスで何も値が返ってこないリソースがいた
        if ( [string]::IsNullOrEmpty($resource) -eq $false){

            # リソースタイプが存在していないものを除外
            if ($resource.ResourceType -eq $null){ continue }        

            # 子リソースを除外（ParentResourceに値が入っている＝子リソース）
            if ($resource.ParentResource -ne $null){ continue }

            $Caller = $item.Caller
            $ResourceId = $item.ResourceId

            # そもそもTagのValueが空なら、CreatedByを書き込み
            if ( $resource.Tags -eq $null ){
                Write-output "$Caller created $ResourceId"
                Set-AzureRmResource -ResourceId $item.ResourceId -Tag @{ createdBy="$Caller" } -Force
            }
            
            # TagのValueは空じゃないけど、Valueの中にCreatedByのキーがなかったら、CreatedByを書き込み
            if ( ($resource.Tags -ne $null) -and ( $resource.Tags.ContainsKey('createdBy') -eq $false )){
                Write-output "$Caller created $ResourceId"
                Set-AzureRmResource -ResourceId $item.ResourceId -Tag @{ createdBy="$Caller" } -Force
            }
        } 
    }
} catch {
    Write-Error $_.Exception  
}
