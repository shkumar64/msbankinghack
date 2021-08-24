function RefreshTokens()
{
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:synapseToken = ((az account get-access-token --resource https://dev.azuresynapse.net) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:managementToken = ((az account get-access-token --resource https://management.azure.com) | ConvertFrom-Json).accessToken
}

#should auto for this.
#az login

#for powershell...
#Connect-AzAccount -DeviceCode

#if they have many subs...
$subs = Get-AzSubscription | Select-Object -ExpandProperty Name

if($subs.GetType().IsArray -and $subs.length -gt 1)
{
    $subOptions = [System.Collections.ArrayList]::new()
    for($subIdx=0; $subIdx -lt $subs.length; $subIdx++)
    {
        $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($subs[$subIdx])", "Selects the $($subs[$subIdx]) subscription."   
        $subOptions.Add($opt)
    }
    $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab','Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(),0)
    $selectedSubName = $subs[$selectedSubIdx]
    Write-Host "Selecting the $selectedSubName subscription"
    Select-AzSubscription -SubscriptionName $selectedSubName
    az account set --subscription $selectedSubName
}

#Change Script here 
$rgName = "FSIBankinghackk";
#$init =  (Get-AzResourceGroup -Name $rgName).Tags["DeploymentId"]
#$random =  (Get-AzResourceGroup -Name $rgName).Tags["UniqueId"]
#$concatString = "$random$init"
$cosmos_account_name = "fsibankinghack" #replaceMe
if($cosmos_account_name.length -gt 43 )
{
$cosmos_account_name = $cosmos_account_name.substring(0,43)
}
$cosmos_database_name = "fsi-marketdata"

RefreshTokens
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name PowerShellGet -Force
Install-Module -Name CosmosDB -Force
$cosmosDbAccountName = $cosmos_account_name
$databaseName = $cosmos_database_name
Write-Host "CosmosDb Account $cosmosDbAccountName"
$cosmos1 = Get-ChildItem "./cosmos" 

$cosmos = Get-ChildItem "./cosmos" | Select BaseName 
#Write-Host "CosmosDb db $cosmos1"

foreach($name in $cosmos)
{
    $collection = $name.BaseName 
    $cosmosDbContext = New-CosmosDbContext -Account $cosmosDbAccountName -Database $databaseName -ResourceGroup $rgName
  #  Write-Host "CosmosDb Account created $cosmosdbCon"
    $path="./cosmos/"+$name.BaseName+".json"

    $document=Get-Content -Raw -Path $path
    $document=ConvertFrom-Json $document

	#Write-Host "CosmosDb json path $path"

    foreach($json in $document)
    {
        Write-Host "json $json"

        $key=$json.TransactionType
        $id = New-Guid
        $date = Get-Date -Format "MM/dd/yyyy"
        $time = Get-Date -Format "HH:mm:ss"
        #Write-Host "date $date"
        #Write-Host "time $time"

        #Write-Host "New id $id"
        #Write-host "adding id"
        $json | Add-Member -MemberType NoteProperty -Name 'id' -Value $id
        $json | Add-Member -MemberType NoteProperty -Name 'date' -Value $date
        $json | Add-Member -MemberType NoteProperty -Name 'time' -Value $time


    
       if(![bool]($json.PSobject.Properties.name -match "TransactionType"))
       {$json | Add-Member -MemberType NoteProperty -Name 'TransactionType' -Value $id}
       $body=ConvertTo-Json $json
       #Write-Host "Item $body"
       #Write-Host "$cosmosDbContext , $collection , $key"
       Start-Sleep -s 3
       $res = New-CosmosDbDocument -Context $cosmosDbContext -CollectionId $collection -DocumentBody $body -PartitionKey $key
    }	
} 
