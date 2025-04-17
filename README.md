# PIM-AutoActivator

A PowerShell script to automatically activate your eligible Azure AD (Entra ID) roles via Microsoft Graph API.

## 🔍 Overview

**PIM-AutoActivator** allows Azure AD users to programmatically activate their **Privileged Identity Management (PIM)** eligible roles.  

This is especially useful for individuals who frequently switch between roles or require quick activation of multiple eligible roles without navigating through the Azure portal.

The script:
- Connects to Microsoft Graph using the `Microsoft.Graph` PowerShell SDK.
- Detects eligible roles for the signed-in user.
- Offers the option to activate **select roles** or **all roles**.
- Skips already active or pending role activations.


## 🧰 Prerequisites

- PowerShell 5.1+ (or PowerShell Core)
- Microsoft.Graph module  
  Install it using:

  ```powershell
  Install-Module Microsoft.Graph -AllowClobber -Force
  ```

 ## 🔧 Parameters

| Parameter	| Description | 
|-----------|-------------|
| -TenantId	| The Azure AD tenant GUID |
| -All	| Optional. Activates all eligible roles |


## 🧪 Usage Examples
🔹 Selective Activation
```
.\PIM-AutoActivator.ps1 -TenantId "<your-tenant-guid>"
```
   _Prompts you to choose which roles to activate_

🔹 Activate All Eligible Roles

```
.\PIM-AutoActivator.ps1 -TenantId "<your-tenant-guid>" -All
```
  _Automatically activates all PIM eligible roles assigned to your account._

 ## 🔐 Scopes Required
The script connects with the following Microsoft Graph scopes:
- RoleEligibilitySchedule.Read.Directory
- RoleManagement.ReadWrite.Directory
- RoleManagement.Read.Directory
- RoleManagement.Read.All
- RoleEligibilitySchedule.ReadWrite.Directory


## 🔄 Updates
```
17 Apr 2025
        Added the MVP script
```
## 📄 License
This project is licensed under the [MIT License](LICENSE).

