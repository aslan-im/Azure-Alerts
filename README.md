# Azure Function App: Teams Alert Notification

## Overview

This Azure Function App processes Azure Monitor alerts and sends formatted messages to a Microsoft Teams channel using a specified webhook URL. The messages include details about the alert, such as the rule name, severity, status, and affected resources. It also generates buttons to view the alert and the affected resource in the Azure portal.

## Files

- **HttpTrigger/run.ps1**: Main script that processes the alert and sends the message to Teams.
- **profile.ps1**: Script executed on every "cold start" of the Function App, used for initialization tasks.
- **local.settings.json**: Local settings for the Function App.
- **requirements.psd1**: Specifies the required PowerShell modules.

## Environment Variables

The script requires the following environment variables:

- `AlertsTeamsWebhookUrl`: Webhook URL for the Teams channel to send alerts.
- `AlertFiredImageUrl`: URL of the image to display when an alert is fired.
- `AlertResolvedImageUrl`: URL of the image to display when an alert is resolved.
- `TenantAddress`: Azure tenant address.

## Functions

### `Get-NotificationTeamsSplat`

Processes the alert data and prepares the Teams message for Azure Service Health Alerts.

### `Get-CommonAlertTeamsSplat`

Processes the alert data and prepares the Teams message for other types of alerts.

## Requirements

This Function App requires the `PSTeams` module to send messages to Microsoft Teams. Ensure that the `PSTeams` module is specified in the `requirements.psd1` file:

```powershell
@{
    'PSTeams' = '2.0.4'
}
```
## Usage

1. Deploy the Function App to Azure.
2. Set the required environment variables in the Azure portal.
3. The Function App will automatically process incoming alerts and send notifications to the specified Teams channel.

