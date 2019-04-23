$Armexist=Get-Module -Name AzureRM.* -ListAvailable
    if(!($Armexist.Count -gt 0))
    {
        Install-Module -Name AzureRm -AllowClobber -Force -Verbose
    }
    $EU=
    $EP=
    $Subscription=
    $AzureSubscriptionTenantId=
    $azureAccountName = $EU
    $azurePassword = ConvertTo-SecureString $EP -AsPlainText -Force
    $psCred = New-Object System.Management.Automation.PSCredential($azureAccountName, $azurePassword)
    Start-Sleep -Seconds 2
    Write-Host $Subscription $AzureSubscriptionTenantId
    $login = Add-AzureRmAccount -SubscriptionName $Subscription -TenantId $AzureSubscriptionTenantId -Credential $psCred 
    if (!$login)
    { 
           return
       } 
    $login
    Write-output "login completed" 
         
    
    #Cypher Technique Function to to encrypted and Decrypt the value from Azure Key Vault
#BEGIN
function Set-Key {
param([string]$string)
$length = $string.length
$pad = 32-$length
if (($length -lt 16) -or ($length -gt 32)) {Throw "String must be between 16 and 32 characters"}
$encoding = New-Object System.Text.ASCIIEncoding
$bytes = $encoding.GetBytes($string + "0" * $pad)
return $bytes
}
function Set-EncryptedData {
param($key,[string]$plainText)
$securestring = new-object System.Security.SecureString
$chars = $plainText.toCharArray()
foreach ($char in $chars) {$secureString.AppendChar($char)}
$encryptedData = ConvertFrom-SecureString -SecureString $secureString -Key $key
return $encryptedData
}
function Get-EncryptedData {
param($key,$data)
$data | ConvertTo-SecureString -key $key |
ForEach-Object {[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($_))}
}

$encryptKey = Set-Key "encryptedpatvalue"
$patkeyEncrypted = Get-AzureKeyVaultSecret -VaultName 'credscankeyvaultprod' -Name 'PATTFVC'

$patKeyDecrypted = Get-EncryptedData -data $patkeyEncrypted.SecretValueText -key $encryptKey

$personalAccessToken=$patKeyDecrypted

####END Cipher technique#######
    
    Get-AzureKeyVaultSecret -VaultName 'credscankeyvaultprod'
    
   [string]$ServerName=(Get-AzureKeyVaultSecret -VaultName 'credscankeyvaultprod' -Name 'SQLservername').SecretValueText   
   [string]$UserName=(Get-AzureKeyVaultSecret -VaultName 'credscankeyvaultprod' -Name 'username').SecretValueText
    [string]$Password=(Get-AzureKeyVaultSecret -VaultName 'credscankeyvaultprod' -Name 'sqlpassword').SecretValueText
    $DbName=(Get-AzureKeyVaultSecret -VaultName 'credscankeyvaultprod' -Name 'DBname').SecretValueText
    
    $Endusername=(Get-AzureKeyVaultSecret -VaultName 'credscankeyvaultprod' -Name 'Euname').SecretValueText
    $Enduserpassword=(Get-AzureKeyVaultSecret -VaultName 'credscankeyvaultprod' -Name 'EUPassword').SecretValueText
    $AZSubscription=(Get-AzureKeyVaultSecret -VaultName 'credscankeyvaultprod' -Name 'AZSubscription').SecretValueText
    $TenantId=(Get-AzureKeyVaultSecret -VaultName 'credscankeyvaultprod' -Name 'Azsubscriptiontenantid').SecretValueText


    $Clonedir = "C:\Credscan\Repoclone"
    $RgName="Credscan-RG"  
    $RgLocation="Central US"
    $storageaccountName="credscangitprodtest"
    $ContainerName="credscancontainergit"


  
    #New-Item -ItemType directory -Path "C:\TFVCRepopathCSV"
    $Armexist=Get-Module -Name AzureRM.* -ListAvailable
    if(!($Armexist.Count -gt 0))
    {
        Install-Module -Name AzureRm -AllowClobber -Force -Verbose
    }
    $EU="$Endusername"
    $EP= "$Enduserpassword"
    $Subscription="$AZSubscription"
    $AzureSubscriptionTenantId="$TenantId"
    $azureAccountName = $EU
    $azurePassword = ConvertTo-SecureString $EP -AsPlainText -Force
    $psCred = New-Object System.Management.Automation.PSCredential($azureAccountName, $azurePassword)
    Start-Sleep -Seconds 2
    $login = Add-AzureRmAccount -SubscriptionName $Subscription -TenantId $AzureSubscriptionTenantId -Credential $psCred 
    if (!$login)
    { 
           return
       } 
    $login
    Write-output "login completed"
        #Set-AzureRmContext cmdlet to set authentication information for cmdlets that we run in this PS session.
         Set-AzureRmContext -SubscriptionName $Subscription
   $rg=Get-AzureRmResourceGroup -Name $RgName -Location $RgLocation -ErrorAction SilentlyContinue
    if(!$rg)
    {
        write-output "Resource Group Created"
        New-AzureRmResourceGroup -Name $RgName -Location $RgLocation
    }
    $storeageaccount=Get-AzureRmStorageAccount -ResourceGroupName $RgName -Name $storageaccountName -ErrorAction SilentlyContinue
    if(!$storeageaccount)
    {
       Write-output "Storage account created"
        $storeageaccount=New-AzureRmStorageAccount -ResourceGroupName $RgName  -Name $storageaccountName -Location $RgLocation -SkuName Standard_LRS -Kind BlobStorage -AccessTier Cool
        New-AzureRmStorageContainer -Name $ContainerName -ResourceGroupName $RgName -StorageAccountName $storeageaccount.StorageAccountName -PublicAccess Blob
       Write-output "Container created"
    }
$count=1
$connectionString = "Server=$ServerName;uid=$UserName; pwd=$Password;Database=$DbName;Integrated Security=False;"
$connection = new-object system.data.SqlClient.SQLConnection($connectionString)
Write-output "credential formed"
do
{
    try
    {
      $connection.Open()
     $command2 = $connection.CreateCommand() 
    $command2.CommandText = "EXEC dbo.usp_GetCredscanGITRepos" 
    $dataAdapt = new-object System.Data.SqlClient.SqlDataAdapter $command2
    $dataS2 = New-Object System.Data.DataSet
   Write-Host $dataAdapt.Fill($dataS2)       
   Write-Host $dataS2.Tables.Count
    
    if($dataS2.Tables.Count -gt 0 -And $dataS2.Tables[0].Rows.Count -gt 0)
   
    {    
        $count = 1
                           
                    
                    $accountname =  $dataS2.Tables[0].Rows[0]["AccountName"]
                    $prjname = $dataS2.Tables[0].Rows[0]["ProjectName"]
                    $repoName = $dataS2.Tables[0].Rows[0]["RepoName"]
                    $RepoId = $dataS2.Tables[0].Rows[0]["ProjID"]
                
            }
            else
            {
            $count = 0
            }
           
            if ($count -eq 1)
            {

       Write-output "entered into while block"
        $connection.Close()
        $dir = "C:\Repoclone\$RepoName"  
        $toolPath ="C:\Credscan\tools\CredentialScanner.exe" 
        $searcher="C:\Credscan\tools\Searchers\buildsearchers.xml"
        $repoLogsOutput="C:\CSV\$RepoName"

        $gitURL="https://$personalAccessToken@$accountName.visualstudio.com"
        $gitFinalRepoPath = "$gitURL/$prjName/_git/$repoName".Trim().Replace(' ', '%20')    

        Write-Output "===Cloning repo $repopath===" 
        git clone $gitFinalRepoPath $dir
        Write-Output "$toolPath $dir $repoLogsOutput" 
        & $toolPath -I "$dir" -S $searcher -O "$repoLogsOutput" -f csv -cp
       
        $connection.Open()
        $query1 = "update CredScanGitRepos set IsProcessed=1, IsAccessed = 0 where ProjID='$RepoId' "
        $command1 = $connection.CreateCommand()
        $command1.CommandText = $query1
        $result = $command1.ExecuteReader()
         $connection.Close()

        Set-AzureStorageBlobContent -Container $ContainerName -File "$repoLogsOutput-matches.csv" -Context $storeageaccount.Context -Force
        Write-Output "====Scan Completed and status updated===="
      
        }
    }
    catch
    {
    throw $_.Exception
    }
}
until ($count -eq 0)
