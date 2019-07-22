<#
.SYNOPSIS
    Downloads and installs the Microsoft Artifacts Credential Provider
    from https://github.com/microsoft/artifacts-credprovider
    to assist in authenticating to Azure Artifact feeds in interactive development
    or unattended build agents.
.PARAMETER AccessToken
    An optional access token for authenticating to Azure Artifacts authenticated feeds.
#>
[CmdletBinding()]
Param (
    [Parameter()]
    [string]$AccessToken
)

$toolsPath = & "$PSScriptRoot\..\azure-pipelines\Get-TempToolsPath.ps1"

if ($IsMacOS -or $IsLinux) {
    $installerScript = "installcredprovider.sh"
    $sourceUrl = "https://raw.githubusercontent.com/microsoft/artifacts-credprovider/master/helpers/installcredprovider.sh"
} else {
    $installerScript = "installcredprovider.ps1"
    $sourceUrl = "https://raw.githubusercontent.com/microsoft/artifacts-credprovider/master/helpers/installcredprovider.ps1"
}

$installerScript = Join-Path $toolsPath $installerScript

if (!(Test-Path $installerScript)) {
    Invoke-WebRequest $sourceUrl -OutFile $installerScript
}

$installerScript = (Resolve-Path $installerScript).Path

if ($IsMacOS -or $IsLinux) {
    chmod u+x $installerScript
}

& $installerScript

if ($AccessToken) {
    $endpoints = @()

    $nugetConfig = [xml](Get-Content -Path "$PSScriptRoot\..\nuget.config")

    $nugetConfig.configuration.packageSources.add |? { $_.value -match '^https://pkgs\.dev\.azure\.com/' } |% {
        $endpoint = New-Object -TypeName PSObject
        Add-Member -InputObject $endpoint -MemberType NoteProperty -Name endpoint -Value $_.value
        Add-Member -InputObject $endpoint -MemberType NoteProperty -Name username -Value ado
        Add-Member -InputObject $endpoint -MemberType NoteProperty -Name password -Value $AccessToken
        $endpoints += $endpoint
    }

    $auth = New-Object -TypeName PSObject
    Add-Member -InputObject $auth -MemberType NoteProperty -Name endpointCredentials -Value $endpoints

    $authJson = ConvertTo-Json -InputObject $auth
    $envVars = @{
        'VSS_NUGET_EXTERNAL_FEED_ENDPOINTS'=$authJson;
    }

    & "$PSScriptRoot\..\azure-pipelines\Set-EnvVars.ps1" -Variables $envVars | Out-Null
}
