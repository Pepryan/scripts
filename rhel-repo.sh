#!/bin/bash

# Set no_proxy to avoid issues when pulling repositories
export no_proxy="http://172.18.217.137"

# Check OS version
if [ -f /etc/redhat-release ]; then
    os_version=$(rpm -E %rhel)
else
    echo "This script is only for RHEL systems"
    exit 1
fi

# List of available repositories based on RHEL version
declare -A repos_rhel7=(
    ["nginx"]="[nginx]
name=Nginx Package for RHEL 7
baseurl=http://172.18.217.137/additional/nginx/el7/nginx/
enabled=1
gpgcheck=0"

    ["docker-ce"]="[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=http://172.18.217.137/additional/docker-ce/el7/docker-ce-stable
enabled=1
gpgcheck=0"

    ["mysql-57"]="[mysql-5.7]
name=Mysql 5.7 for RHEL 7
baseurl=http://172.18.217.137/additional/mysql-57/mysql57-community-el7/
enabled=1
gpgcheck=0"

    ["mysql-80"]="[mysql8]
name=Mysql8 Community for Enterprise Linux 7
enabled=1
gpgcheck=0
baseurl=http://172.18.217.137/additional/rhel/mysql8/mysql80-community-el7/"

    ["remi-php56"]="[php56]
name=Remi Repository PHP Version 5.6 for Enterprise Linux 7
enabled=1
gpgcheck=0
baseurl=http://172.18.217.137/additional/remirepo/rhel7/php56"

    ["remi-php81"]="[php81]
name=Remi Repository PHP Version 8.1 for Enterprise Linux 7
enabled=1
gpgcheck=0
baseurl=http://172.18.217.137/additional/remirepo/rhel7/php81"

    ["remi-php82"]="[php82]
name=Remi Repository PHP Version 8.2 for Enterprise Linux 7
enabled=1
gpgcheck=0
baseurl=http://172.18.217.137/additional/remirepo/rhel7/php82"

    ["postgresql"]="[pgdg-common]
name=PostgreSQL common RPMs for RHEL 7
baseurl=http://172.18.217.137/additional/postgresql/rhel7/pgdg-common/
enabled=1
gpgcheck=0

[pgdg15]
name=PostgreSQL 15 for RHEL 7
baseurl=http://172.18.217.137/additional/postgresql/rhel7/pgdg15/
enabled=1
gpgcheck=0

[pgdg14]
name=PostgreSQL 14 for RHEL 7
baseurl=http://172.18.217.137/additional/postgresql/rhel7/pgdg14/
enabled=1
gpgcheck=0"

    ["proxysql"]="[proxysql]
name=Proxysql for Red Hat Enterprise Linux 7
baseurl=http://172.18.217.137/additional/proxysql/rhel7
enabled=1
gpgcheck=0"

    ["percona"]="[Percona]
name=Percona Server RPMs for Centos 7
baseurl=http://172.18.217.137/additional/percona/el7/Percona
enabled=1
gpgcheck=0"

    ["percona-pxc-57"]="[Percona-PXC-57]
name=Percona Server PXC-57 RPMs for Centos 7
baseurl=http://172.18.217.137/additional/percona/el7/Percona-PXC-57
enabled=1
gpgcheck=0"

    ["zabbix"]="[Zabbix]
name=Zabbix RPMs for RHEL 7
baseurl=http://172.18.217.137/additional/zabbix/rhel7/Zabbix
enabled=1
gpgcheck=0"
)

declare -A repos_rhel8=(
    ["nginx"]="[nginx]
name=Nginx Package for RHEL 8
baseurl=http://172.18.217.137/additional/nginx/el8/nginx/
enabled=1
gpgcheck=0"

    ["docker-ce"]="[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=http://172.18.217.137/additional/docker-ce/el8/docker-ce-stable
enabled=1
gpgcheck=0"

    ["mysql-80"]="[mysql8]
name=Mysql8 Community for Enterprise Linux 8
enabled=1
gpgcheck=0
baseurl=http://172.18.217.137/additional/rhel/mysql8/mysql80-community-el8/"

    ["postgresql"]="[pgdg-common]
name=PostgreSQL common RPMs for RHEL 8
baseurl=http://172.18.217.137/additional/postgresql/rhel8/pgdg-common/
enabled=1
gpgcheck=0

[pgdg16]
name=PostgreSQL 16 for RHEL 8
baseurl=http://172.18.217.137/additional/postgresql/rhel8/pgdg16/
enabled=1
gpgcheck=0

[pgdg15]
name=PostgreSQL 15 for RHEL 8
baseurl=http://172.18.217.137/additional/postgresql/rhel8/pgdg15/
enabled=1
gpgcheck=0"

    ["oracle-instant-client"]="[Oracle-Instant-Client]
name=Oracle-Instant-Client
baseurl=http://172.18.217.137/additional/oracle-instant-client/el8/Oracle-Instant-Client
enabled=1
gpgcheck=0"

    ["remi-php81"]="[php81]
name=Remi Repository PHP Version 8.1 for Enterprise Linux 8
enabled=1
gpgcheck=0
baseurl=http://172.18.217.137/additional/remirepo/rhel8/php81"

    ["remi-php82"]="[php82]
name=Remi Repository PHP Version 8.2 for Enterprise Linux 8
enabled=1
gpgcheck=0
baseurl=http://172.18.217.137/additional/remirepo/rhel8/php82"

    ["zabbix"]="[Zabbix]
name=Zabbix RPMs for RHEL 8
baseurl=http://172.18.217.137/additional/zabbix/rhel8/Zabbix
enabled=1
gpgcheck=0"
)

declare -A repos_rhel9=(
    ["nginx"]="[nginx]
name=Nginx Package for RHEL 9
baseurl=http://172.18.217.137/additional/nginx/el9/nginx/
enabled=1
gpgcheck=0"

    ["docker-ce"]="[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=http://172.18.217.137/additional/docker-ce/el9/docker-ce-stable
enabled=1
gpgcheck=0"

    ["mysql-80"]="[mysql8]
name=Mysql8 Community for Enterprise Linux 9
enabled=1
gpgcheck=0
baseurl=http://172.18.217.137/additional/rhel/mysql8/mysql80-community-el9/"

    ["postgresql"]="[pgdg13]
name=PostgreSQL 13 for RHEL 9
baseurl=http://172.18.217.137/additional/postgresql/rhel9/pgdg13/
enabled=1
gpgcheck=0"

    ["nodejs20"]="[nodejs]
name=Nodejs Package for RHEL 9
baseurl=http://172.18.217.137/additional/nodejs/el9/nodesource-nodejs/
enabled=1
gpgcheck=0"

    ["remi"]="[remi]
name=Remi Repository Full Packages for Enterprise Linux 9
baseurl=http://172.18.217.137/additional/remirepo/rhel9/remi
enabled=1
gpgcheck=0"
)

declare -A repos_rhel7+=(
    ["grafana"]="[grafana-oss]
name=Grafana for RHEL / CentOS \$releasever - \$basearch
baseurl=http://172.18.217.137/additional/grafana/
enabled=1
gpgcheck=0
repo_gpgcheck=0"

    ["elasticsearch"]="[elasticsearch]
name=Elastic Search Packages
baseurl=http://172.18.217.137/additional/elasticsearch/
gpgcheck=0
enabled=1"

    ["mongodb-40"]="[mongodb-org-4.0]
name=MongoDB Repository
baseurl=http://172.18.217.137/additional/mongodb/el7/mongodb-org-4.0/
gpgcheck=0
enabled=1"

    ["fluent-bit"]="[fluent-package]
name=Fluent Package
baseurl=http://172.18.217.137/additional/fluent-package/
gpgcheck=0
enabled=1"

    ["leap"]="[Leapp Utilites]
name=Leap Utilites for Enterprise Linux \$releasever - \$basearch
baseurl=http://172.18.217.137/rhel/rhel7/additional-upgrade
enabled=1
gpgcheck=0
repo_gpgcheck=0"

    ["fuse-exfat"]="[fuse-exfat]
name=fuse-exfat RHEL 7
baseurl=http://172.18.217.137/additional/fuse-exfat
gpgcheck=0
enabled=1"
)

declare -A repos_rhel8+=(
    ["grafana"]="[grafana-oss]
name=Grafana for RHEL / CentOS \$releasever - \$basearch
baseurl=http://172.18.217.137/additional/grafana/
enabled=1
gpgcheck=0
repo_gpgcheck=0"

    ["elasticsearch"]="[elasticsearch]
name=Elastic Search Packages
baseurl=http://172.18.217.137/additional/elasticsearch/
gpgcheck=0
enabled=1"

    ["mongodb-40"]="[mongodb-org-4.0]
name=MongoDB Repository
baseurl=http://172.18.217.137/additional/mongodb/el8/mongodb-org-4.0/
gpgcheck=0
enabled=1"

    ["fuse-exfat"]="[fuse-exfat]
name=fuse-exfat RHEL 8
baseurl=http://172.18.217.137/additional/fuse-exfat
gpgcheck=0
enabled=1"

    ["edb"]="[enterprisedb-enterprise]
name=enterprisedb-enterprise
baseurl=http://172.18.217.137/additional/edb/rhel8/enterprisedb-enterprise
enabled=1
gpgcheck=0

[enterprisedb-enterprise-noarch]
name=enterprisedb-enterprise-noarch
baseurl=http://172.18.217.137/additional/edb/rhel8/enterprisedb-enterprise-noarch
enabled=0
gpgcheck=0

[enterprisedb-enterprise-source]
name=enterprisedb-enterprise-source
baseurl=http://172.18.217.137/additional/edb/rhel8/enterprisedb-enterprise-source
enabled=0
gpgcheck=0"
)

declare -A repos_rhel9+=(
    ["grafana"]="[grafana-oss]
name=Grafana for RHEL / CentOS \$releasever - \$basearch
baseurl=http://172.18.217.137/additional/grafana/
enabled=1
gpgcheck=0
repo_gpgcheck=0"

    ["elasticsearch"]="[elasticsearch]
name=Elastic Search Packages
baseurl=http://172.18.217.137/additional/elasticsearch/
gpgcheck=0
enabled=1"

    ["fuse-exfat"]="[fuse-exfat]
name=fuse-exfat RHEL 9
baseurl=http://172.18.217.137/additional/fuse-exfat
gpgcheck=0
enabled=1"
)

# Tambahkan array untuk informasi khusus repository
declare -A repo_notes=(
    ["docker-ce"]="### Membutuhkan repo extras untuk proses pemasangannya ###"
    ["remi-php56"]="# Untuk php 56, tambahkan juga repo [remi] untuk dependensinya"
    ["edb"]="# Repository untuk EnterpriseDB PostgreSQL"
    ["leap"]="# Utilitas untuk upgrade RHEL 7 ke versi yang lebih tinggi"
    ["percona"]="# Diperlukan untuk dependensi Percona XtraDB Cluster"
    ["percona-pxc-57"]="# Membutuhkan repo percona untuk dependensi (percona-xtrabackup-24)"
    ["zabbix"]="# Jika menggunakan repo local zabbix, package zabbix di EPEL harus di-exclude:
[epel]
excludepkgs=zabbix*
[epel-modular]
excludepkgs=zabbix*
[epel-extras]
excludepkgs=zabbix*"
)

# Definisi warna dan style
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to get appropriate repository list based on OS version
function get_repos() {
    case $os_version in
        7) echo "${!repos_rhel7[@]}" ;;
        8) echo "${!repos_rhel8[@]}" ;;
        9) echo "${!repos_rhel9[@]}" ;;
        *) echo "Unsupported RHEL version: $os_version"; exit 1 ;;
    esac
}

# Function to get repository content based on OS version and repo name
function get_repo_content() {
    local repo_name=$1
    case $os_version in
        7) echo "${repos_rhel7[$repo_name]}" ;;
        8) echo "${repos_rhel8[$repo_name]}" ;;
        9) echo "${repos_rhel9[$repo_name]}" ;;
    esac
}

# Function to display available repositories
function display_repos() {
    echo -e "\n${BOLD}Available repositories for RHEL ${os_version}:${NC}\n"
    
    local repos=$(get_repos)
    # Get maximum repository name length for padding
    local max_length=0
    for repo in $repos; do
        if [ ${#repo} -gt $max_length ]; then
            max_length=${#repo}
        fi
    done
    
    # Sort repositories alphabetically
    for repo in $(echo $repos | tr ' ' '\n' | sort); do
        # Print repository name with padding
        printf "${CYAN}➜ %-${max_length}s${NC}" "$repo"
        
        # If there's a note for this repository
        if [[ -n "${repo_notes[$repo]}" ]]; then
            # Print newline after repo name if note exists
            echo -e "\n  ${YELLOW}⚠ Note:${NC}"
            # Split note by lines and add proper indentation
            echo "${repo_notes[$repo]}" | while IFS= read -r line; do
                if [[ $line == \[*\] ]]; then
                    # Format repository configuration blocks
                    echo -e "    ${BLUE}$line${NC}"
                else
                    # Format regular notes
                    echo -e "    $line"
                fi
            done
            echo "" # Add empty line after notes
        else
            echo "" # Just newline if no notes
        fi
    done
}

# Function to display success/error messages
function print_message() {
    local type=$1
    local message=$2
    case $type in
        "success")
            echo -e "${GREEN}✓ ${message}${NC}"
            ;;
        "error")
            echo -e "${RED}✗ ${message}${NC}"
            ;;
        "info")
            echo -e "${BLUE}ℹ ${message}${NC}"
            ;;
        "warning")
            echo -e "${YELLOW}⚠ ${message}${NC}"
            ;;
    esac
}

# Function to add repository
function add_repository() {
    local repo_name=$1
    local repo_content=$(get_repo_content "$repo_name")
    local repo_file="/etc/yum.repos.d/$repo_name.repo"

    print_message "info" "Adding repository $repo_name to $repo_file"
    echo "$repo_content" | sudo tee $repo_file > /dev/null
}

# Function to update and check repository
function update_repository() {
    local repo_name=$1
    print_message "info" "Cleaning yum cache..."
    sudo yum clean all > /dev/null 2>&1
    
    print_message "info" "Updating and checking repository..."
    
    # Get the actual repo name from the content (text between square brackets)
    local repo_content=$(get_repo_content "$repo_name")
    local actual_repo_name=$(echo "$repo_content" | grep -m 1 '^\[.*\]' | tr -d '[]')
    
    # Menggunakan awk untuk mencari repository tanpa memperhatikan tanda kurung siku
    if sudo yum repolist | awk -v repo="$actual_repo_name" '$1 == repo || $1 == "["repo"]"' | grep -q .; then
        print_message "success" "Repository added successfully."
    else
        print_message "error" "FAILED to add repository, please contact Btech team."
        print_message "info" "To remove the repository, run 'sudo rm /etc/yum.repos.d/${repo_name}.repo'"
        print_message "info" "To check repository status, run 'sudo yum repolist'"
    fi
}

# Function to handle special dependencies
function handle_dependencies() {
    local repo_name=$1
    case $repo_name in
        "percona-pxc-57")
            if [[ $os_version -eq 7 ]]; then
                print_message "warning" "Installing dependencies for Percona XtraDB Cluster 5.7..."
                add_repository "percona"
                sudo yum install -y percona-xtrabackup-24
            fi
            ;;
        "zabbix")
            print_message "warning" "You need to configure EPEL repository to exclude zabbix packages"
            print_message "info" "Add 'excludepkgs=zabbix*' to your EPEL repository configuration"
            ;;
    esac
}

# Main script execution
echo -e "${BOLD}Running on RHEL version: ${GREEN}${os_version}${NC}${NC}\n"
display_repos

echo -e "\n${BOLD}Repository Selection:${NC}"
read -p "$(echo -e ${CYAN}"Enter the name of the repository to add: "${NC})" repo_name

# Check if the repository exists
if [[ $os_version -eq 7 && -z "${repos_rhel7[$repo_name]}" ]] || \
   [[ $os_version -eq 8 && -z "${repos_rhel8[$repo_name]}" ]] || \
   [[ $os_version -eq 9 && -z "${repos_rhel9[$repo_name]}" ]]; then
    print_message "error" "Repository not found for RHEL $os_version!"
    exit 1
fi

# Add repository and update
add_repository "$repo_name"
handle_dependencies "$repo_name"
update_repository "$repo_name" 
