# Ninja RDP Role Manager

PowerShell script to **remove** the currently logged-in user from the local Administrators group and **add** them to the local Remote Desktop Users group. Designed to be run as an elevated script on Windows endpoints and is suitable for RMM platforms like NinjaOne.

---

## Use case

In many environments, users are temporarily granted local admin rights for troubleshooting or software install, but should not remain administrators long-term.

This script:

- Detects the currently logged-in user (`DOMAIN\Username`).
- Removes that user from the local **Administrators** group (if present).
- Adds that user to the local **Remote Desktop Users** group (if not already a member).
- Ensures the script runs only when executed with administrative privileges.

Typical scenarios:

- Post‑elevation cleanup: demote a user from local admin to RDP‑only.
- Aligning endpoints with least privilege while preserving remote support access.

---

## Files

- `Set-CurrentUser-RdpRole.ps1`  
  Main script. Removes the current user from Administrators and adds them to Remote Desktop Users.

- `README.md`  
  Project documentation.

- `LICENSE`  
  MIT License for this repository.

---

## Requirements

- Windows 10/11 or Windows Server.
- PowerShell 5.1 or later.
- Script must run as Administrator (local admin/SYSTEM via RMM).
- At least one user must be interactively logged in when the script runs (for current user detection).

---

## Script behavior

1. **Elevation check**  
   Verifies that PowerShell is running as Administrator. If not, exits with an error message.

2. **Current user detection**  
   Uses `Win32_ComputerSystem.UserName` to detect the currently logged-in user as `DOMAIN\Username`.

3. **User parsing**  
   Splits the string into domain and username components. If parsing fails, exits gracefully.

4. **Local group operations (via ADSI)**  
   - Checks membership in local **Administrators** and removes the user if present.
   - Checks membership in local **Remote Desktop Users** and adds the user if not present.

5. **Console output**  
   Writes clear success/warning/error messages to the console with basic coloring.

---

## Usage

### Local / manual execution

From an elevated PowerShell prompt:

```powershell
.\Set-CurrentUser-RdpRole.ps1
```

What will happen:

- The script will confirm it is running as Administrator.
- It will determine the currently logged-in user.
- It will remove that user from the Administrators group and add them to Remote Desktop Users as needed.

### RMM / NinjaOne usage

1. Create a new PowerShell script in NinjaOne.
2. Paste the contents of `Set-CurrentUser-RdpRole.ps1`.
3. Run the script on the target device as SYSTEM or a local admin.
4. Use this script as:
   - A **follow‑up** or scheduled “cleanup” after a temporary admin elevation script.
   - A one‑shot role adjustment tool to standardize local roles.

You can combine this with a temporary admin script so that:

- A “grant temp admin” script elevates the user.
- This “RDP role manager” script later removes admin and ensures RDP membership.

---

## Notes and limitations

- If no user is interactively logged in, the script exits and does nothing.
- In environments with multiple concurrent sessions, it acts on the user returned by `Win32_ComputerSystem.UserName`, typically the active console session.
- ADSI (`WinNT://`) is used for compatibility on older Windows builds; you can optionally replace the group operations with `Remove-LocalGroupMember` and `Add-LocalGroupMember` if your environment prefers the newer LocalAccounts cmdlets [web:54][web:59].

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.