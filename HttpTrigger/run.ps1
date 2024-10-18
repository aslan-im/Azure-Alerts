<#
.SYNOPSIS
    Sends an alert message to a Microsoft Teams channel using the specified webhook URL.

.DESCRIPTION
    This script processes an Azure Monitor alert and sends a formatted message to a Teams channel.
    The message includes details about the alert, such as the rule name, severity, status, and affected resources.
    It also generates buttons to view the alert and the affected resource in the Azure portal.

.PARAMETER Request
    The HTTP request that triggered this function, containing the alert data.

.PARAMETER TriggerMetadata
    Metadata related to the trigger of the function.

.NOTES
    This script requires environment variables for Teams webhook URL, image URLs, and tenant address.
    version: 2.3.0
    Last changes owner: Aslan Imanalin
#>


using namespace System.Net

param($Request, $TriggerMetadata)

function Get-NotificationTeamsSplat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$RequestData
    )

    $WebhookURL = $env:NotificationsTeamsWebhookUrl

    $NotificationDescription = $RequestData.alertContext.properties.defaultLanguageContent
    $Impact = $RequestData.alertContext.properties.impactedServices | ConvertFrom-Json -Depth 10
    $ImpactedRegions = $RequestData.alertContext.properties.region
    $AffectedResourceName = $Impact.ServiceName
    $ActivityText = $RequestData.alertContext.properties.title

    # Teams message data
    $MessageTitle = "Production Notification"
    $ActivityTitle = "Azure Service Notification"    

    $AlertFiredDate = "Notification Time UTC: $(get-Date -AsUTC $RequestData.essentials.firedDateTime)"
    $MonitoringService = $RequestData.essentials.monitoringService
    $AlertType = $RequestData.essentials.signalType

    $IncomingRequestData = $RequestData
    Write-Output "Incoming Request Data: $IncomingRequestData | ConvertTo-json -Depth 15"

    $StatusColor = "Yellow"
    
    # Teams facts
    $AffectedResourceNameFact = New-TeamsFact -Name "Affected Resource" -Value $AffectedResourceName
    $MonitoringServiceFact = New-TeamsFact -Name "Monitoring Service" -Value $MonitoringService
    $AlertTypeFact = New-TeamsFact -Name "Signal Type" -Value $AlertType
    $AffectedRegionsFact = New-TeamsFact -Name "Impacted Regions" -Value $ImpactedRegions
    $NotificationDescriptionFact = New-TeamsFact -Name "Description" -Value $NotificationDescription
    
    $SectionSplat = @{
        ActivityTitle     = $ActivityTitle
        ActivitySubtitle  = $AlertFiredDate
        ActivityImageLink = $NotificationImageUrl
        ActivityText      = $ActivityText
        ActivityDetails   = @(
            $AffectedResourceNameFact,
            $AffectedRegionsFact
            $MonitoringServiceFact,
            $AlertTypeFact,
            $NotificationDescriptionFact
        )
    }
    
    $TemsSection = New-TeamsSection @SectionSplat

    @{
        URI          = $WebhookURL
        MessageTitle = $MessageTitle
        MessageText  = ""
        Color        = $StatusColor
        Sections     = $TemsSection
    }
}

function Get-CommonAlertTeamsSplat {
    # Environment variables
    $AlertsChannelURL = $env:AlertsTeamsWebhookUrl
    $AlertFiredImageUrl = $env:AlertFiredImageUrl
    $AlertResolvedImageUrl = $env:AlertResolvedImageUrl
    $TenantAddress = $env:TenantAddress

    # URLs
    $AzureUrlsPrefix = "https://portal.azure.com/#@$TenantAddress/resource"
    $AlertId = $RequestData.essentials.alertId
    $TargetResourceId = "$($RequestData.essentials.alertTargetIDs)"
    $AlertUrl = $AzureUrlsPrefix + $AlertId
    $TargetResourceUrl = $AzureUrlsPrefix + $TargetResourceId

    # Alert data
    $AlertRuleName = $RequestData.essentials.alertRule
    $AlertStatus = $RequestData.essentials.monitorCondition

    $AlertCondition = "$($RequestData.alertContext.condition.allOf[0].metricName) $($RequestData.alertContext.condition.allOf[0].operator) $($RequestData.alertContext.condition.allOf[0].threshold)"
    $AlertSeverity = $RequestData.essentials.severity
    $AlertDescription = $RequestData.essentials.description
    $AffectedResourceName = "$($RequestData.essentials.configurationItems[0])"

    # Teams message data
    $MessageTitle = "Production Alert | $AlertStatus"
    $ActivityTitle = "$AlertRuleName $AlertSeverity"

    $AlertFiredDate = "Notification Time UTC: $(get-Date -AsUTC $RequestData.essentials.firedDateTime)"
    $MonitoringService = $RequestData.essentials.monitoringService
    $AlertType = $RequestData.essentials.signalType

    $IncomingRequestData = $RequestData
    Write-Output "Incoming Request Data: $IncomingRequestData | ConvertTo-json -Depth 15"

    if ($AlertStatus -eq "Fired") {
        $ActivityImage = $AlertFiredImageUrl
        $StatusColor = "Red"
    } 
    else { 
        $ActivityImage = $AlertResolvedImageUrl
        $StatusColor = "Green"
    }
    

    # Teams buttons
    $AlertButton = New-TeamsButton -Name "View Alert" -URL $AlertUrl
    $ResourceButton = New-TeamsButton -Name "View Affected Resource" -URL $TargetResourceUrl

    # Teams facts
    $AffectedResourceNameFact = New-TeamsFact -Name "Affected Resource" -Value $AffectedResourceName
    $MonitoringServiceFact = New-TeamsFact -Name "Monitoring Service" -Value $MonitoringService
    $AlertTypeFact = New-TeamsFact -Name "Signal Type" -Value $AlertType
    $AffectedResourceIdFact = New-TeamsFact -Name "Affected Resource ID" -Value $TargetResourceId
    $AlertConditionFact = New-TeamsFact -Name "Alert Condition" -Value $AlertCondition
    
    $SectionSplat = @{
        ActivityTitle     = $ActivityTitle
        ActivitySubtitle  = $AlertFiredDate
        ActivityImageLink = $ActivityImage
        ActivityText      = $AlertDescription
        ActivityDetails   = @(
            $AffectedResourceNameFact,
            $MonitoringServiceFact,
            $AlertTypeFact,
            $AffectedResourceIdFact,
            $AlertConditionFact)
        Buttons           = @($AlertButton, $ResourceButton)
    }
    
    $Section = New-TeamsSection @SectionSplat

    @{
        URI          = $AlertsChannelURL
        MessageTitle = $MessageTitle
        MessageText  = ""
        Color        = $StatusColor
        Sections     = $Section
    }
}

# Request data
$RequestData = $Request.body.data

if ($AlertRuleName -eq 'Azure Service Health Alerts') {
    $SendTeamsSplat = Get-NotificationTeamsSplat -RequestData $RequestData
}
else {
    $SendTeamsSplat = Get-CommonAlertTeamsSplat -RequestData $RequestData
}

Send-TeamsMessage @SendTeamsSplat

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })