param (
    [Parameter(Mandatory = $true)]
    [string]
    $tenantId,
    [Parameter(Mandatory = $true)]
    [string]
    $location,
    [Parameter(Mandatory = $true)]
    [string]
    $resourceGroupName,
    [Parameter(Mandatory = $true)]
    [string]
    $principalId,
    [Parameter(Mandatory = $true)]
    [string]
    $connectionName,
    [Parameter(Mandatory = $true)]
    [string]
    $logicAppName
)


$Properties  = @{
    principal = @{
        type = "ActiveDirectory"
        identity = @{
            tenantId = "$tenantId"
            objectId = "$principalId"
    }
}
}

$policyName = "$connectionName/$logicAppName-$principalId"
$resource = New-AzResource -Location $location -ResourceGroup "$resourceGroupName" -ResourceType "Microsoft.Web/connections/accessPolicies" -ResourceName "$policyName" -ExtensionResourceName $policyName -Properties $Properties -ApiVersion "2018-07-01-preview"  -Force

