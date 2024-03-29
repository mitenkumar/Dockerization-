
# Docker Configuration 

__**Note**__
   - Windows 10 and Windows11, be sure to activate Hyper-V  [configuration review](https://docs.docker.com/desktop/install/windows-install/) and the system requirements in the WSL 2.
   - Docker Desktop running (to handle the "daemon is not running" error)
   - If you getting this issue then run docker desktop then fix this issue.

**1. Installation**

   * Check Docker Installation:
      * The script first checks if Docker is installed on your machine.
      * If not, press 'Y/y' to install Docker end to end.
   * Docker Desktop Installation (Linux/Mac):
      * If you have Docker installed, the script will ask if Docker Desktop is installed on your machine.
      * If not, press 'Y/y' to install Docker Desktop.
      * If you have it installed, press 'N/n'.

**2. Choose Your Project Type:**
   * Specify your project type: Node [N/n], React [R/r], or Angular [A/a].

**3. Node.js Image Version:**
   * The script will determine if a Node.js image is already installed on your machine.
   * If no Node.js image is found, it will prompt you to enter the version of Node.js you want to use.

**4. Enter Docker Image, Tag, and Container Names:**
   * Enter the name for your Docker image, tag, and container.



**Environment**
*  If you have used the `Node JS` framework for creating projects, then a PORT must be declared in the environment file.
  
   * Set Port number value with key like PORT=port_number(eg: 3000).