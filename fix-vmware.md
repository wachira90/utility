# fix vmware

Run “bcdedit /enum {current}”

Note down the hypervisorlaunchtype in case this needs to be reverted

Run “bcdedit /set hypervisorlaunchtype off” to disable hypervisor Close the command prompt after   executing the commands and restart the system.

````
C:\WINDOWS\system32>bcdedit /enum {current}

Windows Boot Loader
-------------------
identifier              {current}
device                  partition=C:
path                    \WINDOWS\system32\winload.exe
description             Windows 10
locale                  en-GB
inherit                 {bootloadersettings}
recoverysequence        {16c108ae-606e-11eb-ac74-ac844666ff49}
displaymessageoverride  Recovery
recoveryenabled         Yes
allowedinmemorysettings 0x15000075
osdevice                partition=C:
systemroot              \WINDOWS
resumeobject            {968fe3b8-60a8-11eb-a6d2-8706bfd742b0}
nx                      OptIn
bootmenupolicy          Standard
hypervisorlaunchtype    Auto

C:\WINDOWS\system32>


bcdedit /set hypervisorlaunchtype off
````


## Turn Off Hyper-V
````
1. Go to "Turn Windows features on or off"
2. Make sure Hyper-v is not ticked.
3. If it is Ticked, untick it and click "Ok".
````

## turn off virtualization-based Security
````
- Edit group policy (gpedit)
- Go to Local Computer Policy > Computer Configuration > Administrative Templates > System
- Double Click on Device Guard on the right hand side to open.
- Double Click on "Turn On Virtualization Security" to open a new window
- It would be "Not Configured", Select "Disable" and click "Ok"
- Close the Group Policy Editor.
- Restart the system
````
