<#
    .SYNOPSIS
    SMTP2GO PowerShell Module for sending emails and text messages.

    .DESCRIPTION
    This module provides functions for sending emails and text messages using the SMTP2GO service. It allows
    setting SMTP2GO credentials and supports sending messages to various carriers' email-to-SMS gateways.

    .OUTPUTS
    The Send-SMTP2GOEmail function sends an email and does not produce any output.
    The Send-SMTP2GOTextMessage function sends a text message via email and does not produce any output.

    .NOTES
    Written by: Matt Urbano

    Change Log
    V1.00, 04/02/24 - Initial version
#>

#region Variables
$NA = ''

$script:SMTP2GOUsername = $NA
$script:SMTP2GOPassword = $NA
$script:SMTP2GOTxtMe    = $NA
$script:SMTP2GOCarrier  = $NA
$script:SMTP2GOFrom     = $NA

$script:Carriers        = ConvertFrom-StringData -StringData @'
ATT     = txt.att.net
Verizon = vtext.com
TMobile = tmomail.net
Sprint  = messaging.sprintpcs.com
'@

$script:Err = 'Use Set-SMTP2GOCredentials to set them.'
#endregion Variables

Function Set-SMTP2GOCredentials {
    <#
        .SYNOPSIS
        Set your SMTP2GO Credentials.
        .DESCRIPTION
        Add a more complete description of what the function does.
        .PARAMETER Username
        Your Username
        .PARAMETER Password
        Your Password (optional - will prompt to keep from typing password in the open)
        .PARAMETER PhoneNumber
        Your PhoneNumber.
        .PARAMETER Carrier
        Your Carrier.
        .PARAMETER From
        Your "From" Email address.
        .EXAMPLE
        Set-SMTP2GOCredentials -Username Value -Password Value -PhoneNumber Value -Carrier Value -From Value
        .NOTES
        Version 1.0 - Initial release
                1.1 - Expanded code
        .LINK
        https://github.com/burn56/SMTP2GO
        .INPUTS
        String
        .OUTPUTS
        None
    #>
    Param (
        [Parameter(Mandatory, HelpMessage = 'Your username')]
        [ValidateNotNullOrEmpty()]
        [string]$Username,
        [string]$Password,
        [Parameter(Mandatory, HelpMessage = 'Your phone number')]
        [ValidateNotNullOrEmpty()]
        [string]$PhoneNumber,
        [Parameter(Mandatory, HelpMessage = 'Phone Carrier: ATT, Verizon, TMobile, or Sprint')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('ATT', 'Verizon', 'TMobile', 'Sprint')]
        [string]$Carrier,
        [Parameter(Mandatory, HelpMessage = 'Your From Email address')]
        [ValidateNotNullOrEmpty()]
        [string]$From
    )

    $script:SMTP2GOUsername = $Username
    If (-not $Password) {
        $pass = Read-Host -Prompt 'What is your password?' -AsSecureString
        $script:SMTP2GOPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass)
        )
    } Else {
        $script:SMTP2GOPassword = $Password
    }

    $script:SMTP2GOTxtMe    = $PhoneNumber
    $script:SMTP2GOCarrier  = $script:Carriers.$($Carrier)
    $script:SMTP2GOFrom     = $From
}

Function Send-SMTP2GOTextMessage {
    <#
        .SYNOPSIS
        Send SMS/Text message.
        .DESCRIPTION
        Send SMS/Text Message.
        .PARAMETER Message
        Message.
        .EXAMPLE
        Send-SMTP2GOTextMessage -Message Value
        .NOTES
        Version 1.0 - Initial release
                1.1 - Expanded code
        .LINK
        URLs to related sites
        https://github.com/burn56/SMTP2GO
        .INPUTS
        String
        .OUTPUTS
        None
    #>
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory, HelpMessage = 'Message')]
        [ValidateNotNullOrEmpty()]
        [string]$Message
    )

    If (-not $script:SMTP2GOTxtMe -or -not $script:SMTP2GOCarrier) {
        Write-Error -Message ('Phone number or carrier not set. {0}' -f $Err)
        return
    }

    $toAddress            = $script:SMTP2GOTxtMe + '@' + $script:SMTP2GOCarrier
    Send-SMTP2GOEmail -To $toAddress -From $script:SMTP2GOFrom -Subject '' -Body $Message
}

Function Send-SMTP2GOEmail {
    <#
        .SYNOPSIS
        Send Email.
        .DESCRIPTION
        Send SMTP2GO Email.
        .PARAMETER To
        To Address.
        .PARAMETER From
        From Address.
        .PARAMETER Subject
        Mail Subject.
        .PARAMETER Body
        Mail Body.
        .EXAMPLE
        Send-SMTP2GOEmail -To jim@company.com -From me@here.net -Subject test -Body "Hello World"
        .NOTES
        Version 1.0 - Initial release
                1.1 - Expanded code
        .LINK
        URLs to related sites
        https://github.com/burn56/SMTP2GO
        .INPUTS
        String
        .OUTPUTS
        None
    #>
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory, HelpMessage = 'To')]
        [ValidateNotNullOrEmpty()]
        [string]$To,
        [string]$From = $script:SMTP2GOFrom,
        [Parameter(Mandatory, HelpMessage = 'Subject')]
        [ValidateNotNullOrEmpty()]
        [string]$Subject,
        [Parameter(Mandatory, HelpMessage = 'Body')]
        [ValidateNotNullOrEmpty()]
        [string]$Body
    )

    If (-not $script:SMTP2GOUsername -or -not $script:SMTP2GOPassword) {
        Write-Error -Message ('SMTP2GO credentials not set. {0}' -f $Err)
        return
    }

    $smtpServer  = 'mail.smtp2go.com'
    $smtpPort    = 2525

    Try {
        $mailMessage = New-Object -TypeName System.Net.Mail.MailMessage -ArgumentList ($From, $To, $Subject, $Body)
        $smtpClient  = New-Object -TypeName Net.Mail.SmtpClient -ArgumentList ($smtpServer, $smtpPort)
        $smtpClient.EnableSsl   = $true
        $smtpClient.Credentials = New-Object -TypeName System.Net.NetworkCredential -ArgumentList ($script:SMTP2GOUsername, $script:SMTP2GOPassword)
        $smtpClient.Send($mailMessage)
    } Catch {
        $_.Exception.Message -replace "`n", ' ' -replace "`r", ' '
    }
}

### I think this goes in psd1
Export-ModuleMember -Function Set-SMTP2GOCredentials, Send-SMTP2GOEmail, Send-SMTP2GOTextMessage #, Get-CarrierEmailMappings 
