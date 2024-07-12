# Define the environments and their respective server lists
$environments = @{
    'dev' = @('DC1', 'DC1')
    'test' = @('DC1', 'DC1')
    'prod' = @('DC1', 'DC1')
}

# Define the path to store the credentials
$credPath = "$env:USERPROFILE\.crmCredentials"

function DeleteEnvCred {
    param (
        [Parmeter(Mandatory=$true)]
        $envTodelete
    )

    Write-Error "$envTodelete"
    
}




function delete_menu {
    param (
        [string]$Title = 'Delete Menu'

    )
    Clear-Host
    Write-Host "================ $Title ================"
    Write-Host "1: delete dev Credential"
    Write-Host "2: delete test Credential"
    Write-Host "3: delete prod Credential"
    Write-Host "Q: delete 'Q' to quit"


    do {
        
        $selection = Read-Host "Please make a selection"
        switch ($selection) {
            '1' {
                Write-Host "You chose Option 1" -ForegroundColor Cyan
            }
            '2' {
                Write-Host "You chose Option 2" -ForegroundColor Green
            }
            '3' {
                Write-Host "You chose Option 3" -ForegroundColor Yellow
            }
            'q' {
                return
            }
            default {
                Write-Host "Invalid selection. Please try again." -ForegroundColor Red ; delete_menu
            }
            # delete_menu
        }
        pause
    } until ($selection -eq 'q')
}



# Function to get credentials for an environment
function Get-CredentialForEnv {
    param (
        [string]$env
    )

    # Ensure the credential directory exists
    if (-not (Test-Path $credPath)) {
        New-Item -Path $credPath -ItemType Directory -Force
    }

    $credFile = Join-Path -Path $credPath -ChildPath "$env.xml"

    if (Test-Path $credFile) {
        # Load the credentials from the file
        $credentials = Import-Clixml -Path $credFile
    } else {
        # Prompt for credentials and store them securely
        $credentials = Get-Credential
        $credentials | Export-Clixml -Path $credFile
    }

    return $credentials
}


# Function to restart CRM services on a list of servers
function Restart-CrmServices {
    param (
        [string]$env,
        [array]$servers
    )

    $credentials = Get-CredentialForEnv -env $env

    foreach ($server in $servers) {
        # Write-Host "Restarting CRM services on $server in $env environment..."
        Invoke-Command -ComputerName $server -Credential $credentials -Authentication Kerberos -ScriptBlock {
            # Replace 'CrmService' with the actual service name
            # Get-Service -Name 'CrmService' | Restart-Service
            hostname; whoami; ipconfig
        }
    }
    Break Restart-CrmServices
}

# Main menu
function Show-Menu {
    Clear-Host
    Write-Host "Select an environment to restart CRM services:"
    $i = 1
    foreach ($env in $environments.Keys) {
        Write-Host "$i. $env"
        $i++
    }
    Write-Host "5. Reset Pass for env"
    Write-Host "0. Exit"

    $selection = Read-Host "Enter your choice"

    switch ($selection) {
        0 { return $null }
        1 { return 'dev' }
        2 { return 'test' }
        3 { return 'prod' }
        5 { return delete_menu}
        default { Write-Host "Invalid selection. Please try again."; Show-Menu }
    }
}



# Main script execution
$selectedEnv = Show-Menu
if ($selectedEnv -and $environments.ContainsKey($selectedEnv)) {
    Write-Host "Selected environment: $selectedEnv" -ForegroundColor Cyan
    $servers = $environments[$selectedEnv]
    Restart-CrmServices -env $selectedEnv -servers $servers
}
