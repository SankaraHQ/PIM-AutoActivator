# PIM-AutoActivator

A PowerShell script to automatically activate your eligible Azure AD (Entra ID) roles via Microsoft Graph API.

## 🔍 Overview

**PIM-AutoActivator** allows Azure AD users to programmatically activate their **Privileged Identity Management (PIM)** eligible roles **for one hour**.

This is especially useful for individuals who frequently switch between roles or require quick activation of multiple eligible roles without navigating through the Azure portal. Keep in mind that after one hour of activation, it will expire and will need another activation to continue access.

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
🔹 **Selective Activation** :  _Prompts you to choose which roles to activate_
```
.\PIM-AutoActivator.ps1 -TenantId "<your-tenant-guid>"
```

🔹 **Activate All Eligible Roles** : _Automatically activates all PIM eligible roles assigned to your account._

```
.\PIM-AutoActivator.ps1 -TenantId "<your-tenant-guid>" -All
```

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
## Disclaimer

**Important**: *PIM-AutoActivator* automates the activation of all eligible roles for a user in Microsoft Entra PIM. While this can save time, activating roles **that aren't immediately needed**, contradicts the principle of least privilege, potentially increasing your security risk.

This script should be used only with full awareness of the risks, ideally as a last resort in time-sensitive or exception-based scenarios. Also, why the activation duration is set to just *one hour* at this point.

In more structured setups, consider using **PIM Role Assignable Groups**, which allow you to activate multiple roles via group membership. This approach works well when users share consistent role combinations. However, for ad-hoc or dynamic needs, where each user may require a different mix of roles, managing such access through groups can become complex and may lead to *group sprawl*.

In such cases, this script may serve as a **practical workaround**—provided it's used judiciously and with a clear understanding of the risks involved.


## 📄 License
This project is licensed under the [MIT License](LICENSE).

