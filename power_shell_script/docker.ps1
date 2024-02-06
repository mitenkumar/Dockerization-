# Define Wait-Docker function
function Wait-Docker {
    # Wait for Docker daemon
    $dockerReady = $false
    $startTime = Get-Date
    $timeout = [TimeSpan]::FromMinutes(5)  # Set timeout to 5 minutes

    while (!$dockerReady -and (Get-Date).Subtract($startTime) -lt $timeout) {
        try {
            docker version > $null  # Use correct command to check Docker status

            if (!$?) {
                throw "Docker daemon is not running yet"
            }

            $dockerReady = $true
        } catch {
            Write-Host "Trying to connect to Docker daemon. Please wait..."
            Start-Sleep -Seconds 15
        }
    }

    if (!$dockerReady) {
        throw "Timed out waiting for Docker Daemon to start."
    }

    Write-Host "Successfully connected to Docker Daemon."
}

# Check if Docker is installed
$dockerInstalled = Get-Command -Name docker -ErrorAction SilentlyContinue

if (-not $dockerInstalled) {
    Write-Host "Docker is not installed on this machine."

    # Prompt user to install Docker
    $installDocker = Read-Host "Do you want to install Docker? (Y/N)"

    if ($installDocker -eq 'Y' -or $installDocker -eq 'y') {
        # Download Docker Desktop Installer
        $dockerInstallerUrl = "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
        $dockerInstallerPath = "$env:TEMP\DockerDesktopInstaller.exe"
        Invoke-WebRequest -Uri $dockerInstallerUrl -OutFile $dockerInstallerPath

        # Install Docker Desktop
        Start-Process -Wait -FilePath $dockerInstallerPath

        # Clean up the downloaded installer
        Remove-Item -Path $dockerInstallerPath -Force

        Write-Host "Docker has been installed successfully."

        # Start Docker Desktop
        $dockerDesktopPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
        if (Test-Path $dockerDesktopPath) {
            Write-Host "Checking if Docker Desktop is already running..."
            $dockerProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue

            if ($dockerProcess -eq $null) {
                Write-Host "Starting Docker Desktop..."
                Start-Process -FilePath "$dockerDesktopPath"
                Write-Host "Waiting for Docker Desktop to start..."
                Wait-Docker
            } else {
                Write-Host "Docker Desktop is already running."
            }
        } else {
            Write-Host "Docker Desktop not found. Please install Docker Desktop manually."
            return
        }
    } else {
        Write-Host "Docker installation skipped. Please install Docker manually if needed."
        return
    }
} else {
    Write-Host "Docker is already installed."
}

# Check if Docker is installed
$dockerInstalled = Get-Command -Name docker -ErrorAction SilentlyContinue

if ($dockerInstalled) {
    # Docker is installed
    Write-Host "Docker is installed on this machine."
    
    # Get Docker version
    $dockerVersion = docker --version
    Write-Host "Docker version: $dockerVersion"
} else {
    # Docker is not installed
    Write-Host "Docker is not installed on this machine."
}

 
# # Docker Desktop installed manually, check and start Docker Desktop
<# $dockerProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
 
if ($dockerProcess -eq $null) {
    Write-Host "Starting Docker Desktop..."
    Start-Process -FilePath "$dockerDesktopPath"
    Write-Host "Waiting for Docker Desktop to start..."
    Write-Host "The process may take some time."
 
    # Allow some time for Docker Desktop to start before attempting to connect
    Start-Sleep -Seconds 15
 
    # Suppress messages during the Wait-Docker function
    $null = Wait-Docker
} 
 else { #>
#  else {
    # Docker is already installed, check if Docker Desktop is running
    $dockerDesktopPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerDesktopPath) {
        Write-Host "Checking if Docker Desktop is already running..."
        $dockerProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue

        if ($dockerProcess -eq $null) {
            Write-Host "Starting Docker Desktop..."
            Start-Process -FilePath "$dockerDesktopPath"
            Write-Host "Waiting for Docker Desktop to start..."
            Wait-Docker
        } else {
            Write-Host "Docker Desktop is already running."
        }
    } else {
        Write-Host "Docker Desktop not found. Please install Docker Desktop manually."
        return
    }
#  }
# Wait for Docker to come to a steady state
    Wait-Docker
 
  # Check if Node.js images are already present
$nodeImages = docker images node --format "{{.Tag}}"
 
if ($nodeImages.Count -eq 0) {
    # No existing Node.js images, ask the user to specify a version
    $validVersion = $false

do {
    $selectedNodeVersion = Read-Host "Please specify the Node.js version you want to use (e.g., alpine, 21.5)"

    # If the user didn't specify a version, default to "latest"
    if (-not $selectedNodeVersion) {
        $selectedNodeVersion = "latest"
    }

    # Attempt to pull the specified Node.js version from Docker Hub
    $pullOutput = docker pull "node:$selectedNodeVersion" 2>&1

    # Check if the pull was successful or encountered an error
    if ($pullOutput -match "manifest for node:$selectedNodeVersion not found") {
        Write-Host "The specified Node.js version ('$selectedNodeVersion') is either invalid or not available."
    } else {
        $validVersion = $true
        Write-Host "Node.js version '$selectedNodeVersion' successfully pulled."
    }
} until ($validVersion)
 
} else {
    # Existing Node.js images, ask the user to choose from the list or specify another version
    Write-Host "You already have Node.js images with the following versions:"
    $nodeImageOptions = @()
 
    # Add existing versions to the options
    foreach ($image in $nodeImages) {
        $nodeImageOptions += $image
    }
 
    # Add 'other' option
    $nodeImageOptions += "other"
 
    # Assume $nodeImageOptions has been populated with available Node.js versions
 
    while ($true) {
        # Ask the user to choose a Node.js version
        Write-Host "You have the following Node.js images on your machine:"
        for ($i = 0; $i -lt $nodeImageOptions.Count; $i++) {
            Write-Host ("[{0}] node:{1}" -f ([char]($i + 97)), $nodeImageOptions[$i])
        }
 
        $userChoice = Read-Host "Please enter the letter corresponding to your choice (a/b/c/... or 'other')"
 
        # Check if the input is a valid letter within the range of available choices
        if ($userChoice -match '^[a-z]$' -and ([int][char]::ToLower($userChoice) -ge 97) -and ([int][char]::ToLower($userChoice) -le 97 + $nodeImageOptions.Count - 1)) {
            # Valid choice selected
            break  # Break out of the loop as a valid choice has been made
        } else {
            Write-Host "Invalid choice. Please enter a letter between 'a' and '$([char]($nodeImageOptions.Count + 96))'."
        }
    }
 
    if ($userChoice -ge 'a' -and $userChoice -le [char]($nodeImageOptions.Count + 96)) {
        if ($userChoice -eq [char]($nodeImageOptions.Count + 96)) {
            # User chose 'other', ask for a specific version
            $validVersion = $false
 
            do {
                $selectedNodeVersion = Read-Host "Please specify the Node.js version you want to use (e.g., alpine, 21.5)"
               
                # Attempt to pull the specified Node.js version from Docker Hub
                $pullOutput = docker pull "node:$selectedNodeVersion" 2>&1
               
                # Check if the pull was successful or encountered an error
                if ($pullOutput -match "manifest for node:$selectedNodeVersion not found") {
                    Write-Host "The specified Node.js version ('$selectedNodeVersion') is either invalid or not available."
                } else {
                    $validVersion = $true
                    Write-Host "Node.js version '$selectedNodeVersion' successfully pulled."
                }
            } until ($validVersion)
 
        } else {
            $selectedNodeVersion = $nodeImageOptions[[int][char]::ToLower($userChoice) - 97]
        }
    } else {
        Write-Host "Invalid choice. Exiting script."
        return
    }
}
 
    # Fetch the installed Node.js version
    $installedNodeVersion = docker images node --format "{{.Tag}}" | Select-Object -First 1
 
    # Ask for user inputs for Docker run command
    $validInput = $false
 
do {
    $projectType = Read-Host "Specify project type:  Node [N/n], React [R/r], or Angular [A/a]"
 
    if ($projectType -eq "A" -or $projectType -eq "a") {
        $validInput = $true
        Write-Host "Selected project type: Angular"
    } elseif ($projectType -eq "R" -or $projectType -eq "r") {
        $validInput = $true
        Write-Host "Selected project type: React"
    } elseif ($projectType -eq "N" -or $projectType -eq "n") {
        $validInput = $true
        Write-Host "Selected project type: Node"
    } else {
        Write-Host "Please specify a valid project type: Node [N/n], React [R/r], or Angular [A/a]"
    }
} until ($validInput)
 
    # Set the default npm command, additional commands, and default ports
    $npmCommand = "npm start"
    $additionalCommands = ""
    $defaultImageName=""
    $defaultTagName=""
    $defaultContainerName=""
    $defaultHostPort = ""
    $defaultContainerPort = ""
 
    # Adjust npm command and ports based on project type
    if ($projectType -eq 'A' -or $projectType -eq 'a') {
        $npmCommand = "ng serve --host 0.0.0.0 --port 4200"
        $additionalCommands = "RUN npm install -g @angular/cli"
        $defaultHostPort = "4200"
        $defaultContainerPort = "4200"
    } elseif ($projectType -eq 'R' -or $projectType -eq 'r') {
        $npmCommand = "npm start"
        $defaultHostPort = "3000"
        $defaultContainerPort = "3000"
    } elseif ($projectType -eq 'N' -or $projectType -eq 'n') {
      $configFileName = "environment"
        $projectDirectory = Split-Path -Path $PWD.Path -Parent
        $environmentFilePath = Get-ChildItem -Path $projectDirectory -Filter $configFileName -Recurse -File | Select-Object -First 1
 
        if ($environmentFilePath) {
            $environmentFileContent = Get-Content -Path $environmentFilePath.FullName
 
        # Extract the hostport value from the environment file
        $hostPort = ($environmentFileContent | Select-String -Pattern '^\s*PORT\s*=\s*(.*)').Matches.Groups[1].Value
 
        # Assigning the ports
        $npmCommand = "node app.js"
        $defaultContainerPort = $hostPort
        $defaultHostPort = $hostPort
       
        }
    }
    $npmCommandArray = $npmCommand -split '\s+'
    $quotedNpmCommandArray = $npmCommandArray | ForEach-Object { '"{0}"' -f $_ }
    $cmdString = 'CMD [{0}]' -f ($quotedNpmCommandArray -join ', ')
 
    # Ask for user inputs for Docker run command
    $project_name = (Get-Item -Path $PWD).BaseName
    $default_container_name = "${project_name}_container"
    $default_tag_name = "latest"
 
# Get image name from user input or use default
do {
    $image_name = Read-Host "Enter the image name (Default: $project_name)"
    if (-not $image_name) {
        $image_name = $project_name
    }
 
    # Validate that the Docker image name doesn't already exist
    if (docker images -q $image_name) {
        Write-Host "Error: Image name already exists. Please choose a different name."
    }
} while (docker images -q $image_name)
 
# Get tag name from user input or use default
$tag_name = Read-Host "Enter the tag name (Default: $default_tag_name) "
if (-not $tag_name) {
    $tag_name = $default_tag_name
}
 
# Get container name from user input or use default
do {
    $container_name = Read-Host "Enter the container name (Default: $default_container_name)"
    if (-not $container_name) {
        $container_name = $default_container_name
    }
 
    # Validate that the Docker container name doesn't already exist
    if (docker ps -a --format "{{.Names}}" | Select-String -SimpleMatch $container_name) {
        Write-Host "Error: Container name already exists. Please choose a different name."
    }
} while (docker ps -a --format "{{.Names}}" | Select-String -SimpleMatch $container_name)
 
# Check if the default host port is in use by a Docker container
if (docker ps -a --format "{{.Ports}}" | Select-String -SimpleMatch $defaultHostPort) {
    Write-Host "Error: Default host port $defaultHostPort is already in use. Please choose a different port."
   
    # Get host port from user input
    do {
        $host_port = Read-Host "Enter the host port (Default: $defaultHostPort)"
        if (-not $host_port) {
            $host_port = $defaultHostPort
        }
 
        # Validate that the host port is not in use
        if (docker ps -a --format "{{.Ports}}" | Select-String -SimpleMatch $host_port) {
            Write-Host "Error: Host port $host_port is already in use. Please choose a different port."
        }
    } while (docker ps -a --format "{{.Ports}}" | Select-String -SimpleMatch $host_port)
} else {
    # If default host port is not in use, use it
    $host_port = $defaultHostPort
}$container_port = $defaultContainerPort
Write-Host "Your default host port is: $host_port"
Write-Host "Your default container port is: $container_port"
 
    # Create Dockerfile content
    $dockerfileContent = @"
# Use the official Node.js image
FROM node:$selectedNodeVersion
 
# Set the working directory inside the container
WORKDIR /app
 
# Copy package.json and package-lock.json to the working directory
COPY package.json ./
$additionalCommands
 
# Install project dependencies
RUN npm install
 
# Copy the entire project to the working directory
COPY . .
 
# Expose the specified port
EXPOSE $container_port
 
# Command to start the application
 $cmdString
"@
 
    # Save Dockerfile
    Set-Content -Path "Dockerfile" -Value $dockerfileContent -Force
 
    Write-Host "Dockerfile created successfully."
 
    # Create docker-compose.yml content
    $docker_compose_content = @"
version: '3.8'
 
services:
  ${container_name}:
    container_name: ${container_name}
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - '.:/app'
      - '/app/node_modules'
    ports:
      - "${host_port}:${container_port}"
    restart: always
"@
 
    # Save docker-compose.yml file
    Set-Content -Path "docker-compose.yml" -Value $docker_compose_content -Force
 
    Write-Host "docker-compose.yml created successfully."
 
    # Create .dockerignore file content
    $docker_ignore_content = @"
node_modules
npm-debug.log
build
.dockerignore
**/.git
**/.DS_Store
**/node_modules
"@
 
    # Save .dockerignore file
    Set-Content -Path ".dockerignore" -Value $docker_ignore_content -Force
 
    Write-Host ".dockerignore file created successfully."
   
    # Build the Docker image
    $image_tag = "${image_name}:${tag_name}"
    Write-Host "Building Docker image $image_tag..."
    docker build -t $image_tag .
 
    # Construct and execute docker run command
    $docker_run_command = "docker run -p ${host_port}:${container_port} -d --name $container_name $image_tag"
    Invoke-Expression $docker_run_command
 
    Write-Host "Docker image built and container started successfully."