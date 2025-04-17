<#
#############################################################################  
#                                                                           #  
#   This Sample Code is provided for the purpose of illustration only       #  
#   and is not intended to be used in a production environment.  THIS       #  
#   SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT    #  
#   WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT    #  
#   LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS     #  
#   FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, royalty-free    #  
#   right to use and modify the Sample Code and to reproduce and distribute #  
#   the object code form of the Sample Code, provided that You agree:       #  
#   (i) to not use Our name, logo, or trademarks to market Your software    #  
#   product in which the Sample Code is embedded; (ii) to include a valid   #  
#   copyright notice on Your software product in which the Sample Code is   #  
#   embedded; and (iii) to indemnify, hold harmless, and defend Us and      #  
#   Our suppliers from and against any claims or lawsuits, including        #  
#   attorneys' fees, that arise or result from the use or distribution      #  
#   of the Sample Code.                                                     # 
#                                                                           # 
#   This posting is provided "AS IS" with no warranties, and confers        # 
#   no rights. Use of included script samples are subject to the terms      # 
#   specified at http://www.microsoft.com/info/cpyright.htm.                # 
#                                                                           #  
#   Author: Sankara Narayanan M S                                           #  
#   Version 1.0                                                             #  
#                                                                           #  
#############################################################################  
.SYNOPSIS
    Automatically activates Azure AD PIM eligible roles for the signed-in user using Microsoft Graph API.
    Created by: Sankara Narayanan M S
    Creation Date: 17 April 2025
    Date Last Modified: 17 April 2025
.DESCRIPTION
    This PowerShell script allows selective or bulk activation of eligible Azure AD (Entra ID) roles via Microsoft Graph.
    It checks for active assignments and pending requests to avoid duplication. Useful for users who frequently switch roles.
.EXAMPLE
    As a user, you may run this to activate any particular eligible roles that's assigned to your account
    PS C:\> .\PIM-AutoActivator.ps1 -TenantId "<tenant_guid>"
.EXAMPLE
    As a user, run may run this to activate all of the eligible roles that's assigned to your account
    PS C:\> .\PIM-AutoActivator.ps1 -TenantId "<tenant_guid>" -All
.NOTES
    - If a role is already active or a request is pending, it will be skipped.
    - Activations last for 4 hours (configurable inside the script).

    - The script will connect to the Microsoft Graph service and collect the required information. 
        To install the latest modules:
        Install-Module Microsoft.Graph -AllowClobber -Force

        If PowerShell logs an error message for MaximumFunctionCount or MaximumVariableCount. This can be increased using the below.
        
        $MaximumFunctionCount = 8192 
        $MaximumVariableCount = 8192

.LINK
    Github 
    https://github.com/microsoftgraph/msgraph-sdk-powershell 
    Microsoft Graph PowerShell Module
    https://www.powershellgallery.com/packages/Microsoft.Graph
#>

param (
    [switch]$All,
    [string]$TenantId
)

#Requires -Modules Microsoft.Graph

# Connect to Graph
Connect-MgGraph -TenantId $tenantId -Scopes "RoleEligibilitySchedule.Read.Directory, RoleManagement.ReadWrite.Directory, RoleManagement.Read.Directory, RoleManagement.Read.All, RoleEligibilitySchedule.ReadWrite.Directory" -NoWelcome

$context = Get-MgContext
if (!$context) {
    Write-Host "Unable to connect to MS Graph" -ForegroundColor Red
    return
}

Write-Host "`nSuccessfully connected to MSGraph" -ForegroundColor DarkGreen
$currentUser = (Get-MgUser -UserId $context.Account).Id

Write-Host "`nGetting the list of your PIM eligible roles..." -ForegroundColor Cyan

# Get eligible roles
$eligibleRoles = Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -Filter "principalId eq '$currentUser'"

# Get all role definitions
$roleDefinitions = Get-MgRoleManagementDirectoryRoleDefinition

# Get currently active role assignments
$activeAssignments = Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance -Filter "principalId eq '$currentUser'"

# Prepare indexed eligible roles with friendly names
$index = 1
$eligibleRolesWithNames = foreach ($role in $eligibleRoles) {
    $matchedRole = $roleDefinitions | Where-Object { $_.Id -eq $role.RoleDefinitionId }
    [PSCustomObject]@{
        Index            = $index++
        RoleDefinitionId = $role.RoleDefinitionId
        RoleName         = $matchedRole.DisplayName
        Scope            = $role.DirectoryScopeId
        PrincipalId      = $role.PrincipalId
    }
}

if (-not $All) {
    # Show eligible roles
    Write-Host "`nEligible Roles:"
    $eligibleRolesWithNames | ForEach-Object {
        Write-Host "$($_.Index)) $($_.RoleName)"
    }

    # Prompt user input
    $selectedInput = Read-Host "`nEnter comma-separated numbers for roles to activate (e.g., 1,3)"
    $selectedIndices = $selectedInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
}
else {
    # Select all roles automatically
    $selectedIndices = $eligibleRolesWithNames.Index
    Write-Host "`n🔁 Activating all eligible roles..." -ForegroundColor Yellow
}

# Activate selected roles
foreach ($index in $selectedIndices) {
    $selectedRole = $eligibleRolesWithNames | Where-Object { $_.Index -eq [int]$index }

    if ($null -ne $selectedRole) {
        $isAlreadyActive = $activeAssignments | Where-Object {
            $_.RoleDefinitionId -eq $selectedRole.RoleDefinitionId -and
            $_.DirectoryScopeId -eq $selectedRole.Scope -and
            $_.PrincipalId -eq $selectedRole.PrincipalId
        }

        if ($isAlreadyActive) {
            Write-Host "`nℹ️  Skipping '$($selectedRole.RoleName)' — already active." -ForegroundColor DarkYellow
            continue
        }

        Write-Host "`nActivating role: $($selectedRole.RoleName)..." -ForegroundColor DarkYellow

        $activationParams = @{
            Action           = "selfActivate"
            PrincipalId      = $selectedRole.PrincipalId
            RoleDefinitionId = $selectedRole.RoleDefinitionId
            DirectoryScopeId = $selectedRole.Scope
            Justification    = "Activated via the PIM-AutoActivator script"
            ScheduleInfo     = @{
                StartDateTime = (Get-Date).ToString("o")
                Expiration    = @{
                    Type     = "AfterDuration"
                    Duration = "PT1H"
                }
            }
        }

        # Check for pending requests
        $pendingRequests = Get-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -Filter "principalId eq '$($selectedRole.PrincipalId)' and roleDefinitionId eq '$($selectedRole.RoleDefinitionId)'" -All

        $hasPending = $pendingRequests | Where-Object {
            $_.Status -and $_.Status.ToString().ToLower() -eq 'pending'
        }

        if ($hasPending) {
            Write-Host "ℹ️  Role '$($selectedRole.RoleName)' already has a pending activation request. Skipping..." -ForegroundColor Yellow
            continue
        }


        try {
            New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $activationParams | Out-Null
            Write-Host "Activated role: $($selectedRole.RoleName)" -ForegroundColor Green
        }
        catch {
            $errorMessage = $_.Exception.Message

            if ($errorMessage -match 'PendingRoleAssignmentRequest' -or $errorMessage -match 'There is already an existing pending Role assignment request') {
                Write-Host "⚠️  '$($selectedRole.RoleName)' may already be activated — Graph API says a pending request exists. Skipping..." -ForegroundColor Yellow
            }
            else {
                Write-Host "❌ Failed to activate $($selectedRole.RoleName): $errorMessage" -ForegroundColor Red
            }
        }

    }
    else {
        Write-Host "⚠️  Invalid selection: $index" -ForegroundColor Red
    }
}

Disconnect-MgGraph | Out-Null
Write-Host "`nDisconnected from MS Graph.`n" -ForegroundColor DarkGray
