# Define the paths to the SillyTavern and Kobold CPP ROCM executables or scripts
$SillyTavernPath = "C:\Users\steph\OneDrive\Desktop\AI\SillyTavern.lnk"
$KoboldCppRocmPath = "C:\Users\steph\OneDrive\Desktop\AI\koboldcpp_rocm.exe"

# Create the scheduled task actions
$Action1 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File $SillyTavernPath"
$Action2 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File $KoboldCppRocmPath"

# Set the trigger to run at startup
$Trigger = New-ScheduledTaskTrigger -AtStartup

# Set the task principal to run with highest privileges
$Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Create the scheduled task
$Task = New-ScheduledTask -Action $Action1, $Action2 -Trigger $Trigger -Principal $Principal -Description "Automatically start SillyTavern and Kobold CPP ROCM at system startup with admin privileges."

# Register the scheduled task
Register-ScheduledTask -TaskName "StartSillyTavernAndKoboldCPP" -InputObject $Task -Force
