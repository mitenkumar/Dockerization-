#!/bin/bash

# Function to check if Docker is installed
check_docker_installed() {
  command -v docker &> /dev/null
}

# Function to install Docker Desktop on Linux
install_docker_desktop_linux() {
  wget https://desktop.docker.com/linux/main/amd64/docker-desktop-4.19.0-amd64.deb -P ~/Downloads/
  sudo apt install ~/Downloads/docker-desktop-*.deb
  systemctl --user start docker-desktop
}

# Function to start Docker engine based on OS
start_docker_engine() {
  # Now start Docker Desktop or Docker Engine based on the OS
  if [ "$(detect_os)" == "linux" ]; then
    systemctl --user start docker-desktop
  elif [ "$(detect_os)" == "darwin" ]; then
    open --background -a Docker
  fi
}

# Function to wait for Docker Desktop to be running
wait_for_docker_desktop() {
  echo "Waiting for Docker Desktop to start..."
  local loading_progress="."

  while ! docker info &> /dev/null; do
    sleep 1
    loading_progress+=" #"
    echo -ne "\rMay take a few minutes to start progress: [$loading_progress]"
  done

  echo -e "\nDocker Desktop is now running."
}

# Function to get the installed Docker version
get_installed_docker_version() {
  echo "Starting Docker engine..."
  start_docker_engine
  wait_for_docker_desktop
}

# Function to update Docker
update_docker() {
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
}

# Function to install Docker on Linux
install_docker_linux() {
  sudo apt install gnome-terminal
  sudo apt remove docker-desktop
  sudo apt-get update
  sudo apt install software-properties-common curl apt-transport-https ca-certificates -y
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt install docker-ce docker-ce-cli containerd.io uidmap -y
  wget https://desktop.docker.com/linux/main/amd64/docker-desktop-4.19.0-amd64.deb -P ~/Downloads/
  sudo apt install ~/Downloads/docker-desktop-*.deb
}

# Function to install Docker on macOS using Homebrew
install_docker_macos() {
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install --cask docker
}

# Function to pull a Docker image
pull_docker_image() {
  local image_name=$1
  local image_version=$2
  docker pull "$image_name:$image_version"
}

# Function to create Docker configuration files
create_docker_files() {
  local project_type=$1
  local version=$2
  local default_running_port=$3
  local container_port=$4
  local container_name=$5
  local cmd_command=""
if [ "${project_type^^}" == "A" ] || [ "$project_type" == "a" ]; then
    cmd_command='["ng", "serve", "--host", "0.0.0.0", "--port", "4200"]'
elif [ "${project_type^^}" == "R" ] || [ "$project_type" == "r" ]; then
  cmd_command='["npm", "start"]'
else
  cmd_command='["node", "app.js"]'
fi


  cat > Dockerfile <<EOL
# Use the official Node.js image as a base image
FROM node:${version:-alpine}

# Set working directory
WORKDIR /app

# Install app dependencies
COPY package.json ./
$([ "$project_type" == "A" ] || [ "$project_type" == "a" ] && echo 'RUN npm install -g @angular/cli')

# Install project dependencies
RUN npm install

# Add app
COPY . .

# Expose the port on which the app will run (adjust as needed)
EXPOSE ${default_running_port}

# Start the app
CMD $cmd_command
EOL

  cat > docker-compose.yml <<EOL
version: '3.8'

services:
  $container_name:
    container_name: $container_name
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - '.:/app'
      - '/app/node_modules'
    ${default_running_port:+ports:
      - "$default_running_port:$container_port"}
    restart: always
EOL

  cat > .dockerignore <<EOL
node_modules
npm-debug.log
build
.dockerignore
**/.git
**/.DS_Store
**/node_modules
EOL
}

# Function to create a Makefile
create_makefile() {
  cat > Makefile <<EOL
build:
  docker-compose build

run:
  docker-compose up -d

stop:
  docker-compose down
EOL
}

# Function to build and run Docker container
build_and_run() {
  local default_running_port=$1
  local container_port=$2
  local image_name=$3
  local tag_name=$4
  local container_name=$5
  echo "Building the Docker image..."
  if docker build -t "$image_name:$tag_name" .; then
    echo "Docker image '$image_name:$tag_name' built successfully."
    
    echo "Running the Docker container..."
    if docker run -p "$default_running_port:$container_port" -d --name "$container_name" "$image_name:$tag_name"; then
      echo "Docker container '$container_name' based on image '$image_name:$tag_name' is now running."
      echo "Host port: $default_running_port, Container port: $container_port"
    else
      echo "Error: Failed to run the Docker container. Please check the logs for more details."
    fi
  else
    echo "Error: Failed to build the Docker image. Please check the build logs for more details."
  fi
}

# Function to check if the container already exists
check_existing_container() {
  local container_name=$1
  docker ps -a --format '{{.Names}}' | grep -q "$container_name"
}
# Detect the operating system
detect_os() {
  OSTYPE=$(uname -s | tr '[:upper:]' '[:lower:]')
  echo "$OSTYPE"
}

OS=$(detect_os)
echo "You are using $OS on your machine."

# Check if Docker is already installed with a version
if ! check_docker_installed; then
echo  -e "\033[1;31mYour system does not have Docker installed.\033[0m"
while true; do
  read -p "Please install Docker? (y/n): " install_docker
  install_docker_lowercase=$(echo "$install_docker" | tr '[:upper:]' '[:lower:]')

  if [[ "$install_docker_lowercase" == "y" || "$install_docker_lowercase" == "yes" ]]; then
    if [ "$OS" == "linux" ] || [ "$OS" == "linux-gnu" ]; then
      install_docker_linux
    elif [ "$OS" == "darwin" ]; then
      install_docker_macos
    else
      echo "Unsupported operating system."
      exit 1
    fi
    get_installed_docker_version
    break  # Exit the loop if a valid input is provided
  elif [[ "$install_docker_lowercase" == "n" || "$install_docker_lowercase" == "no" ]]; then
    echo "Docker installation skipped."
    exit 0  # Exit the script with a successful status code
  else
    echo "Invalid input. Please enter 'yes' (y) or 'no' (n)."
  fi
done
else
  # Docker is already installed, check if Docker Desktop is installed
  docker_version=$(docker --version | awk '{print $3}')
  echo -e "\033[92m✓\033[0m You have Docker version $docker_version installed."
  echo -e "\033[1;31m• NOTICE:~\033[0m Make sure you have Docker Desktop installed."
  echo "1)If you have Docker Desktop installed, press N/n to continue."
  echo "2)If not, press 'Y/y' to install Docker Desktop."
 read -p "Do you want to install Docker Desktop? (y/n): " have_docker_desktop

while [[ ! "$have_docker_desktop" =~ ^[ynYYesNOo]+$ ]]; do
  echo "Invalid choice. Please enter 'y' or 'n'."
  read -p "Do you want to install Docker Desktop? (y/n): " have_docker_desktop
done

if [[ "$have_docker_desktop" =~ ^[nN][oO]*$ ]]; then
  echo "Starting Docker Desktop..."
  start_docker_engine
  wait_for_docker_desktop
else
  install_docker_desktop_linux
fi
# get_installed_docker_version
fi

# Specify project type: Angular [A/a], React [R/r], or Node [default_running_portN/n]
read -p "Specify project type: Node [N/n] , React [R/r], or Angular [A/a]: " project_type

while [[ "${project_type^^}" != "A" && "${project_type^^}" != "R" && "${project_type^^}" != "N" ]]; do
  echo "Invalid project type. Please enter 'A' for Angular, 'R' for React, or 'N' for Node."
  read -p "Specify project type:  Node [N/n] , React [R/r], or Angular [A/a]: " project_type
done

project_type=${project_type:-React}

# Pull the Node.js image from Docker Hub
existing_node_images=($(docker images -q --filter "reference=node" --format "{{.Tag}}" | sort -u))

if [ ${#existing_node_images[@]} -gt 0 ]; then
  echo "You have the following Node.js images on your machine:"
  options=()
  chars=( {a..z} )
  for ((i=0; i<${#existing_node_images[@]}; i++)); do
    options+=("${chars[i]})[node:${existing_node_images[i]}]")
  done
  options+=("${chars[${#existing_node_images[@]}]})[other]")
  for option in "${options[@]}"; do
    echo "$option"
  done

  while true; do
    read -p "Please enter the letter corresponding to your choice (a/b/c/... or 'other'): " selected_letter
    valid_option=false
    for option in "${options[@]}"; do
      if [[ "$selected_letter" == "${option:0:1}" ]]; then
        valid_option=true
        break
      fi
    done

    if [ "$valid_option" = true ]; then
      break
    else
      echo "Invalid choice. Please enter a valid letter corresponding to the options (a/b/c/... or 'other')."
    fi
  done

  selected_option=${options[$(( $(printf "%d" "'$selected_letter") - 97 ))]}
  if [[ $selected_option == *"other"* ]]; then
      while true; do
        read -p "Enter the version of the Node.js image (e.g., 'alpine', '14', '14-alpine'): " node_version
        if docker pull "node:$node_version" &> /dev/null; then
          echo "Node.js image with version $node_version found. Continuing..."
          break
        else
          echo "Error: Node.js image with version $node_version not found. Please provide a valid version."
        fi
      done
    else
      node_version=$(echo "$selected_option" | sed 's/.*\[node:\(.*\)\]/\1/')
      echo "Selected Node.js image version: $node_version"
    fi
  else
    read -p "Enter the version of the Node.js image (e.g., 'alpine', '14', '14-alpine'): " node_version
    while true; do
      if docker pull "node:$node_version" &> /dev/null; then
        echo "Node.js image with version $node_version found. Continuing..."
        break
      else
        echo "Error: Node.js image with version $node_version not found. Please provide a valid version."
        read -p "Enter the version of the Node.js image (e.g., 'alpine', '14', '14-alpine'): " node_version
      fi
    done
  fi
while true; do
  case "${project_type^^}" in
    "R")
      default_running_port="3000"
      container_port="3000"
      ;;
    "A")
      default_running_port="4200"
      container_port="4200"
      ;;
    "N")
      config_file_name="environment"
      project_directory=$(dirname "$PWD")
      environment_file_path=$(find "$project_directory" -name "$config_file_name" -type f -print -quit)

      if [ -f "$environment_file_path" ]; then
        host_port=$(grep -oP '^\s*PORT\s*=\s*\K.*' "$environment_file_path" 2>/dev/null)
        default_running_port=${host_port}
        container_port=${host_port}
      else
        echo "Environment file '$config_file_name' not found in the parent directory."
        read -p "Enter the host port for the application (default is 8080): " host_port
        while ! [[ "$host_port" =~ ^[0-9]+$ ]]; do
          echo "Invalid input. Please enter a valid port number."
          read -p "Please enter a different host port: " host_port
        done

        default_running_port=${host_port}
        container_port=${host_port}
      fi
      ;;
    *)
      echo "Invalid project type. Please enter 'A' for Angular, 'R' for React, or 'N' for Node."
      read -p "Specify project type: Node [N/n], React [R/r], or Angular [A/a]: " project_type
      continue
      ;;
  esac
  # Check if the port is already in use by another Docker container
  while docker inspect --format '{{.NetworkSettings.Ports}}' $(docker ps -aq) 2>/dev/null | grep -q "$default_running_port/tcp"; do
    echo -e "\033[1;31mError:\033[0m Port $default_running_port is already in use by another Docker container."
    read -p "Please enter a different host port: " default_running_port
    while ! [[ "$default_running_port" =~ ^[0-9]+$ ]]; do
      echo "Invalid input. Please enter a valid port number."
      read -p "Please enter a different host port: " default_running_port
    done
  done
  break
done

project_name=$(basename "$(pwd)")
default_container_name="${project_name}_container"
default_tag_name="latest"
check_existing_image() {
  local image_name="$1"
  docker images -q "$image_name" | grep -q .
}
read -p "Enter the name for your Docker image or project (default is $project_name): " image_name
image_name=${image_name:-$project_name}
while check_existing_image "$image_name"; do
  read -p $'\e[31mImage already exists\e[0m. Please enter a different name: ' image_name
done
read -p "Enter the name of tag for your image (default is $default_tag_name): " tag_name
tag_name=${tag_name:-$default_tag_name}
read -p "Enter the container name (default is $default_container_name): " container_name
container_name=${container_name:-$default_container_name}
while check_existing_container "$container_name"; do
  read -p $'\e[31mContainer already exists\e[0m. Please enter a different name:' container_name
done
create_docker_files "$project_type" "$node_version" "$default_running_port" "$container_port" "$container_name"
create_makefile
echo "Docker configuration files for the Node.js image created successfully."
# Build and run the Docker container
build_and_run "$default_running_port" "$container_port" "$image_name" "$tag_name" "$container_name"
echo "Service started successfully."