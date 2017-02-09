function Get-DocDBKey([System.String]$Verb = '',[System.String]$ResourceId = '',
        [System.String]$ResourceType = '',[System.String]$Date = '',[System.String]$masterKey = '') {
    Add-Type -AssemblyName System.Web
    $keyBytes = [System.Convert]::FromBase64String($masterKey) 
    $text = @($Verb.ToLowerInvariant() + "`n" + $ResourceType.ToLowerInvariant() + "`n" + $ResourceId + "`n" + $Date.ToLowerInvariant() + "`n" + "" + "`n")
    $body =[Text.Encoding]::UTF8.GetBytes($text)
    $hmacsha = new-object -TypeName System.Security.Cryptography.HMACSHA256 -ArgumentList (,$keyBytes) 
    $hash = $hmacsha.ComputeHash($body)
    $signature = [System.Convert]::ToBase64String($hash)
        
    return [System.Web.HttpUtility]::UrlEncode($('type=master&ver=1.0&sig=' + $signature))
}

function Get-UTCDate() {
    $date = $(Get-Date).ToUniversalTime()
    return $date.ToString("r", [System.Globalization.CultureInfo]::InvariantCulture)
}

function Get-DocDBDatabases([string]$accountName, [string]$key) {
    $BaseUri = "https://" + $accountName + ".documents.azure.com"
    $uri = $BaseUri + "/dbs"
    $headers = New-DocDBHeader -resType dbs -key $key
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
    return $response.Databases
}

function Get-DocDBCollections([string]$DBName, [string]$accountName, [string]$key){
    $BaseUri = "https://" + $accountName + ".documents.azure.com"
    $uri = $BaseUri + "/" + "dbs/" + $DBName + "/colls"
    $headers = New-DocDBHeader -resType colls -resourceId $("dbs/" + $DBName) -key $key
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
    return $response.DocumentCollections
}

function New-DocDBHeader([string]$action = "get",[string]$resType, [string]$resourceId, [String]$key) {
    $apiDate = Get-UTCDate
    $auth = Get-DocDBKey -Verb $action -ResourceType $resType -ResourceId $resourceId -Date $apiDate -masterKey $Key
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("x-ms-date", $apiDate) 
    $headers.Add("Authorization", $auth)
    $headers.Add("x-ms-version", '2015-12-16')
    return $headers
}

#Post json query
function New-DocDBQuery([switch]$NoClean, [string]$JSONQuery, [string]$DBName, [string]$collection, [string]$accountName, [string]$key){
    $BaseUri = "https://" + $accountName + ".documents.azure.com"
    $collName = "dbs/"+$DBName+"/colls/" + $collection
    $DBName = "dbs/" + $databaseName
    $headers = New-DocDBHeader -action Post -resType docs -resourceId $collName -key $key
    $headers.Add("x-ms-documentdb-is-upsert", "true")
    $uri = $BaseUri + "/" + $collName + "/docs"

    Write-host ("Calling " + $uri)
    try
        {
        $JSONQuery | ConvertFrom-Json|out-null
        }
    catch
        {
        Throw "Problem with JSON input"
        break
        }
    try
        {
        $response = Invoke-RestMethod $uri -Method Post -Body $JSONQuery -ContentType 'application/query+json' -Headers $headers
        }
    catch
        {
        Throw $_.Exception.Message
        break
        }
    if($NoClean)
        {
        return $response
        }
    else
        {
        return Get-CleanDocDBResponse -DocDBOutput $response
        }
}

#Post Document
function Set-DocDBDocument{
    [CmdletBinding(DefaultParameterSetName='JSON')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'JSON')]
        [string]$JSONdocument,
        [string]$DBName, 
        [string]$collection,
        [string]$accountName,
        [string]$key,
        [Parameter(Mandatory = $true, ParameterSetName = 'PSO')]
        [PSCustomObject]$PSdocument
    )
    if($PSdocument)
        {
        $document = $PSdocument|ConvertTo-Json
        }
    elseif($JSONDocument)
        {
    try
        {
        $JSONDocument | ConvertFrom-Json|out-null
        }
    catch
        {
        Throw "Problem with JSON input"
        break
        }
        $document = $JSONDocument
        }
    $BaseUri = "https://" + $accountName + ".documents.azure.com"
    $collName = "dbs/"+$DBName+"/colls/" + $collection
    $DBName = "dbs/" + $databaseName
    $headers = New-DocDBHeader -action Post -resType docs -resourceId $collName -key $key
    $headers.Add("x-ms-documentdb-is-upsert", "true")
    $uri = $BaseUri + "/" + $collName + "/docs"

    Write-host ("Calling " + $uri)

    $response = Invoke-RestMethod $uri -Method Post -Body $document -ContentType 'application/json' -Headers $headers
    return $response
}
    
function Get-CleanDocDBResponse($DocDBOutput){
if($DocDBOutput.Documents -ne $null)
    {
    $CleanResponse = $DocDBOutput.Documents|Select-Object * -ExcludeProperty _*
    return $CleanResponse
    }
else
    {
    $ErrorActionPreference = 'SilentlyContinue'
    $DocDBOutput|ConvertFrom-Json -ErrorVariable converterr -ErrorAction SilentlyContinue
    if($converterr -like "*Cannot convert the JSON string because a dictionary that was converted from the string contains the duplicated keys*")
        {
        $DuplicateKey = [regex]::Match($converterr,"\'(.*?)\'").captures.groups[1].value
        $NewDocDBOutput = $DocDBOutput -replace($DuplicateKey,$($DuplicateKey))
        if($NewDocDBOutput -ne $null)
            {
            return $($NewDocDBOutput|convertfrom-json).Documents|Select-Object * -ExcludeProperty _*
            }
        else
            {
            $ErrorActionPreference = 'Stop'
            Write-Error "Problem converting data to PSObject please use -NoClean argument."
            }
        }
    else
        {
        $ErrorActionPreference = 'Stop'
        Write-Error "Problem converting data to PSObject please use -NoClean argument."
        }
    }
}