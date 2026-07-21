<#
.SYNOPSIS
Removes the currently logged-in user from the local Administrators group and adds them to the local Remote Desktop Users group.

.DESCRIPTION
- Ensures the script is running as Administrator.
- Detects the current logged-in user as DOMAIN\Username using Win32_ComputerSystem.
- Uses ADSI (WinNT://) to:
  - Remove the user from the local Administrators group (if present).
  - Add the user to the local Remote Desktop Users group (if not already a member).

Designed for use as a post-elevation “cleanup” script or as a role-adjustment tool in RMM platforms such as NinjaOne.

.EXAMPLE
.\Set-CurrentUser-RdpRole.ps1
#>

# Ensure script runs as Administrator
if (-not (
    [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as an Administrator. Please restart PowerShell as an Administrator and try again."
    Exit 1
}

Write-Host "=== Starting RDP Role Manager Script ===" -ForegroundColor Cyan

# Get the current logged-in user (DOMAIN\Username)
$currentUser = (Get-WmiObject -Class Win32_ComputerSystem).UserName

if (-not $currentUser) {
    Write-Error "No user is currently logged in. Exiting script."
    Exit 1
}

$userParts = $currentUser.Split('\')
if ($userParts.Count -ne 2) {
    Write-Error "Unable to parse the current user's domain and username from '$currentUser'. Exiting script."
    Exit 1
}

$domain   = $userParts[0]
$username = $userParts[1]

Write-Host "Current logged-in user: $currentUser" -ForegroundColor Cyan

# Remove the current user from the local Administrators group
try {
    $adminGroup = [ADSI]"WinNT://./Administrators,group"
    $memberPath = "WinNT://$domain/$username"

    if ($adminGroup.IsMember($memberPath)) {
        Write-Host "Removing $currentUser from the Administrators group..." -ForegroundColor Yellow
        $adminGroup.Remove($memberPath)
        Write-Host "Successfully removed $currentUser from the Administrators group." -ForegroundColor Green
    } else {
        Write-Host "$currentUser is not a member of the Administrators group." -ForegroundColor Yellow
    }
} catch {
    Write-Error "Failed to remove $currentUser from the Administrators group. Error: $_"
}

# Add the current user to the Remote Desktop Users group
try {
    $rdpGroup   = [ADSI]"WinNT://./Remote Desktop Users,group"
    $memberPath = "WinNT://$domain/$username"

    if (-not $rdpGroup.IsMember($memberPath)) {
        Write-Host "Adding $currentUser to the Remote Desktop Users group..." -ForegroundColor Yellow
        $rdpGroup.Add($memberPath)
        Write-Host "Successfully added $currentUser to the Remote Desktop Users group." -ForegroundColor Green
    } else {
        Write-Host "$currentUser is already a member of the Remote Desktop Users group." -ForegroundColor Yellow
    }
} catch {
    Write-Error "Failed to add $currentUser to the Remote Desktop Users group. Error: $_"
}

Write-Host "=== Script execution completed. ===" -ForegroundColor Cyan