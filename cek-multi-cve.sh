#!/bin/bash

# Script untuk memeriksa multiple CVE vulnerabilities
# CVE-2019-15504/15505 (Kernel USB vulnerability)
# CVE-2007-4559 (Python tarfile module)
# CVE-2014-1745 (webkit2gtk3)
# CVE-2021-20325 (httpd mod_proxy dan mod_session)

# ========== KONFIGURASI ==========
# File yang berisi daftar IP instance
instances_file="instances.txt"

# User untuk koneksi SSH (ditambahkan ubuntu)
users=("ubuntu" "cloud-user" "centos")

# Kunci SSH
ssh_key="~/devops.pem"

# File output
output_file="hasil-multi-cve-check.csv"

# Konfigurasi untuk skip IP berdasarkan range
# Set ke "true" untuk skip, "false" untuk tidak skip
SKIP_10_IPS="false"    # Skip IP 10.x.x.x
SKIP_172_IPS="true"    # Skip IP 172.x.x.x
SKIP_192_IPS="false"   # Skip IP 192.x.x.x

# Konfigurasi CVE yang akan dicek (true/false)
CHECK_CVE_2019_15504="true"   # Kernel USB vulnerability
CHECK_CVE_2007_4559="true"    # Python tarfile
CHECK_CVE_2014_1745="true"    # webkit2gtk3
CHECK_CVE_2021_20325="true"   # httpd mod_proxy/mod_session

# ========== END KONFIGURASI ==========

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fungsi untuk logging dengan timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Fungsi untuk menampilkan konfigurasi
show_configuration() {
    echo -e "${BLUE}========================================"
    echo "           KONFIGURASI SCRIPT"
    echo -e "========================================${NC}"
    echo "Instances file: $instances_file"
    echo "SSH users: ${users[*]}"
    echo "SSH key: $ssh_key"
    echo "Output file: $output_file"
    echo "Skip IP 10.x.x.x: $SKIP_10_IPS"
    echo -e "${YELLOW}Skip IP 172.x.x.x: $SKIP_172_IPS${NC}"
    echo "Skip IP 192.x.x.x: $SKIP_192_IPS"
    echo ""
    echo -e "${PURPLE}CVE Checks Enabled:${NC}"
    echo "  CVE-2019-15504/15505 (Kernel USB): $CHECK_CVE_2019_15504"
    echo "  CVE-2007-4559 (Python tarfile): $CHECK_CVE_2007_4559"
    echo "  CVE-2014-1745 (webkit2gtk3): $CHECK_CVE_2014_1745"
    echo "  CVE-2021-20325 (httpd): $CHECK_CVE_2021_20325"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Fungsi untuk parsing command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-10)
                SKIP_10_IPS="true"
                shift
                ;;
            --include-10)
                SKIP_10_IPS="false"
                shift
                ;;
            --skip-172)
                SKIP_172_IPS="true"
                shift
                ;;
            --include-172)
                SKIP_172_IPS="false"
                shift
                ;;
            --skip-192)
                SKIP_192_IPS="true"
                shift
                ;;
            --include-192)
                SKIP_192_IPS="false"
                shift
                ;;
            --skip-all-private)
                SKIP_10_IPS="true"
                SKIP_172_IPS="false"
                SKIP_192_IPS="true"
                shift
                ;;
            --include-all-private)
                SKIP_10_IPS="false"
                SKIP_172_IPS="true"
                SKIP_192_IPS="false"
                shift
                ;;
            --enable-cve-kernel)
                CHECK_CVE_2019_15504="true"
                shift
                ;;
            --disable-cve-kernel)
                CHECK_CVE_2019_15504="false"
                shift
                ;;
            --enable-cve-python)
                CHECK_CVE_2007_4559="true"
                shift
                ;;
            --disable-cve-python)
                CHECK_CVE_2007_4559="false"
                shift
                ;;
            --enable-cve-webkit)
                CHECK_CVE_2014_1745="true"
                shift
                ;;
            --disable-cve-webkit)
                CHECK_CVE_2014_1745="false"
                shift
                ;;
            --enable-cve-httpd)
                CHECK_CVE_2021_20325="true"
                shift
                ;;
            --disable-cve-httpd)
                CHECK_CVE_2021_20325="false"
                shift
                ;;
            --enable-all-cve)
                CHECK_CVE_2019_15504="true"
                CHECK_CVE_2007_4559="true"
                CHECK_CVE_2014_1745="true"
                CHECK_CVE_2021_20325="true"
                shift
                ;;
            --disable-all-cve)
                CHECK_CVE_2019_15504="false"
                CHECK_CVE_2007_4559="false"
                CHECK_CVE_2014_1745="false"
                CHECK_CVE_2021_20325="false"
                shift
                ;;
            --instances-file)
                instances_file="$2"
                shift 2
                ;;
            --output-file)
                output_file="$2"
                shift 2
                ;;
            --ssh-key)
                ssh_key="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Fungsi untuk menampilkan help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "IP Range Options:"
    echo "  --skip-10               Skip IP addresses starting with 10.x.x.x"
    echo "  --include-10            Include IP addresses starting with 10.x.x.x (default)"
    echo "  --skip-172              Skip IP addresses starting with 172.x.x.x (default)"
    echo "  --include-172           Include IP addresses starting with 172.x.x.x"
    echo "  --skip-192              Skip IP addresses starting with 192.x.x.x"
    echo "  --include-192           Include IP addresses starting with 192.x.x.x (default)"
    echo "  --skip-all-private      Skip all private IP ranges (10.x, 192.x)"
    echo "  --include-all-private   Include all private IP ranges (10.x, 192.x)"
    echo ""
    echo "CVE Check Options:"
    echo "  --enable-cve-kernel     Enable CVE-2019-15504/15505 (Kernel USB) check"
    echo "  --disable-cve-kernel    Disable CVE-2019-15504/15505 check"
    echo "  --enable-cve-python     Enable CVE-2007-4559 (Python tarfile) check"
    echo "  --disable-cve-python    Disable CVE-2007-4559 check"
    echo "  --enable-cve-webkit     Enable CVE-2014-1745 (webkit2gtk3) check"
    echo "  --disable-cve-webkit    Disable CVE-2014-1745 check"
    echo "  --enable-cve-httpd      Enable CVE-2021-20325 (httpd) check"
    echo "  --disable-cve-httpd     Disable CVE-2021-20325 check"
    echo "  --enable-all-cve        Enable all CVE checks"
    echo "  --disable-all-cve       Disable all CVE checks"
    echo ""
    echo "File Options:"
    echo "  --instances-file FILE   Specify instances file (default: instances.txt)"
    echo "  --output-file FILE      Specify output CSV file (default: hasil-multi-cve-check.csv)"
    echo "  --ssh-key FILE          Specify SSH key file (default: ~/devops.pem)"
    echo "  --help, -h              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                              # Run with default settings (all CVE checks enabled)"
    echo "  $0 --disable-cve-kernel         # Disable kernel CVE check"
    echo "  $0 --enable-cve-python --disable-cve-webkit  # Only check Python CVE"
    echo "  $0 --include-172 --disable-all-cve --enable-cve-httpd  # Only httpd CVE + include 172.x.x.x"
}

# Hapus file output jika sudah ada dan tulis header CSV
initialize_output_file() {
    local header="ip,user,auth_method,os_version,connection_status"
    
    if [[ "$CHECK_CVE_2019_15504" == "true" ]]; then
        header+=",cve_2019_15504_kernel_version,cve_2019_15504_vulnerable,cve_2019_15504_module_status"
    fi
    
    if [[ "$CHECK_CVE_2007_4559" == "true" ]]; then
        header+=",cve_2007_4559_rhel_version,cve_2007_4559_installed_patches,cve_2007_4559_status"
    fi
    
    if [[ "$CHECK_CVE_2014_1745" == "true" ]]; then
        header+=",cve_2014_1745_rhel_version,cve_2014_1745_installed_patches,cve_2014_1745_status"
    fi
    
    if [[ "$CHECK_CVE_2021_20325" == "true" ]]; then
        header+=",cve_2021_20325_httpd_version,cve_2021_20325_rhel_version,cve_2021_20325_vulnerable,cve_2021_20325_status"
    fi
    
    echo "$header" > "$output_file"
}

# Fungsi untuk test koneksi SSH dengan timeout
test_ssh_connection() {
    local ip=$1
    local user=$2
    local use_key=$3
    
    if [[ "$use_key" == "true" ]]; then
        timeout 15 ssh -i "$ssh_key" -l "$user" -o "ConnectTimeout=5" -o "ServerAliveInterval=5" -o "ServerAliveCountMax=2" -o "GSSAPIAuthentication=no" -o "PasswordAuthentication=no" -o "StrictHostKeyChecking=no" "$ip" "echo 'test'" &>/dev/null
    else
        timeout 15 ssh -l "$user" -o "ConnectTimeout=5" -o "ServerAliveInterval=5" -o "ServerAliveCountMax=2" -o "GSSAPIAuthentication=no" -o "PasswordAuthentication=yes" -o "StrictHostKeyChecking=no" "$ip" "echo 'test'" &>/dev/null
    fi
}

# Fungsi untuk menjalankan command via SSH dengan timeout
run_ssh_command() {
    local ip=$1
    local user=$2
    local use_key=$3
    local command=$4
    
    if [[ "$use_key" == "true" ]]; then
        timeout 20 ssh -i "$ssh_key" -l "$user" -o "ConnectTimeout=5" -o "ServerAliveInterval=5" -o "ServerAliveCountMax=2" -o "GSSAPIAuthentication=no" -o "PasswordAuthentication=no" -o "StrictHostKeyChecking=no" "$ip" "$command" 2>/dev/null
    else
        timeout 20 ssh -l "$user" -o "ConnectTimeout=5" -o "ServerAliveInterval=5" -o "ServerAliveCountMax=2" -o "GSSAPIAuthentication=no" -o "PasswordAuthentication=yes" -o "StrictHostKeyChecking=no" "$ip" "$command" 2>/dev/null
    fi
}

# Fungsi untuk memeriksa apakah IP harus di-skip berdasarkan range
should_skip_ip() {
    local ip=$1
    local skip_reason=""
    
    if [[ "$SKIP_10_IPS" == "true" && "$ip" =~ ^10\. ]]; then
        skip_reason="10.x.x.x"
        return 0  # Skip
    elif [[ "$SKIP_172_IPS" == "true" && "$ip" =~ ^172\. ]]; then
        skip_reason="172.x.x.x"
        return 0  # Skip
    elif [[ "$SKIP_192_IPS" == "true" && "$ip" =~ ^192\. ]]; then
        skip_reason="192.x.x.x"
        return 0  # Skip
    else
        return 1  # Don't skip
    fi
}

# Fungsi untuk memeriksa CVE-2019-15504/15505 (Kernel USB)
check_cve_2019_15504() {
    local ip=$1
    local user=$2
    local use_key=$3
    
    # Check kernel version
    local kernel_version=$(run_ssh_command "$ip" "$user" "$use_key" "uname -r")
    
    # Check if kernel is vulnerable (below kernel-4.18.0-553)
    local kernel_vulnerable="Unknown"
    if [[ -n "$kernel_version" ]]; then
        if [[ "$kernel_version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)-([0-9]+) ]]; then
            local major=${BASH_REMATCH[1]}
            local minor=${BASH_REMATCH[2]}
            local patch=${BASH_REMATCH[3]}
            local build=${BASH_REMATCH[4]}
            
            if [[ $major -lt 4 ]] || \
               [[ $major -eq 4 && $minor -lt 18 ]] || \
               [[ $major -eq 4 && $minor -eq 18 && $patch -eq 0 && $build -lt 553 ]]; then
                kernel_vulnerable="VULNERABLE"
            else
                kernel_vulnerable="Not Vulnerable"
            fi
        else
            kernel_vulnerable="Cannot Parse Version"
        fi
    fi
    
    # Check if technisat_usb2 module is loaded
    local module_loaded=$(run_ssh_command "$ip" "$user" "$use_key" "lsmod | grep technisat_usb2")
    local module_status
    
    if [[ -n "$module_loaded" ]]; then
        module_status="LOADED - POTENTIALLY VULNERABLE"
    else
        module_status="Not Loaded - SAFE"
    fi
    
    echo "${kernel_version:-Unknown},${kernel_vulnerable},${module_status}"
}

# Fungsi untuk memeriksa CVE-2007-4559 (Python tarfile)
check_cve_2007_4559() {
    local ip=$1
    local user=$2
    local use_key=$3
    
    # Check RHEL version
    local rhel_version=$(run_ssh_command "$ip" "$user" "$use_key" "
        if [[ -f /etc/redhat-release ]]; then
            cat /etc/redhat-release | grep -oE 'release [0-9]+' | cut -d' ' -f2
        else
            echo 'Not RHEL'
        fi
    ")
    
    if [[ "$rhel_version" != "8" && "$rhel_version" != "9" ]]; then
        echo "Not RHEL 8/9,N/A,SKIPPED - Not RHEL 8/9"
        return
    fi
    
    # Define expected patches based on RHEL version
    local expected_patches=""
    if [[ "$rhel_version" == "8" ]]; then
        expected_patches="RHSA-2023:6914 RHSA-2023:7024 RHSA-2023:7034 RHSA-2023:7050 RHSA-2023:7151 RHSA-2023:7176"
    elif [[ "$rhel_version" == "9" ]]; then
        expected_patches="RHSA-2023:6324 RHSA-2023:6494 RHSA-2023:6659 RHSA-2023:6694"
    fi
    
    # Check for installed security patches related to Python packages
    local installed_patches=$(run_ssh_command "$ip" "$user" "$use_key" "
        sudo yum updateinfo list --security installed 2>/dev/null | grep -E 'python|pip' | awk '{print \$1}' | sort -u | tr '\\n' ' ' || echo 'Unable to check'
    ")
    
    # Determine status based on installed patches
    local status="VULNERABLE"
    if [[ "$installed_patches" == "Unable to check" ]]; then
        status="UNABLE TO VERIFY"
    elif [[ -n "$installed_patches" ]]; then
        # Check if any of the expected patches are installed
        local has_patch=false
        for patch in $expected_patches; do
            if [[ "$installed_patches" == *"$patch"* ]]; then
                has_patch=true
                break
            fi
        done
        
        if [[ "$has_patch" == true ]]; then
            status="PATCHED"
        else
            status="VULNERABLE - Missing required patches"
        fi
    else
        status="VULNERABLE - No security patches found"
    fi
    
    echo "RHEL ${rhel_version},${installed_patches:-None},${status}"
}

# Fungsi untuk memeriksa CVE-2014-1745 (webkit2gtk3)
check_cve_2014_1745() {
    local ip=$1
    local user=$2
    local use_key=$3
    
    # Check RHEL version
    local rhel_version=$(run_ssh_command "$ip" "$user" "$use_key" "
        if [[ -f /etc/redhat-release ]]; then
            cat /etc/redhat-release | grep -oE 'release [0-9]+' | cut -d' ' -f2
        else
            echo 'Not RHEL'
        fi
    ")
    
    if [[ "$rhel_version" != "8" && "$rhel_version" != "9" ]]; then
        echo "Not RHEL 8/9,N/A,SKIPPED - Not RHEL 8/9"
        return
    fi
    
    # Check if webkit2gtk3 is installed
    local webkit_installed=$(run_ssh_command "$ip" "$user" "$use_key" "rpm -q webkit2gtk3 2>/dev/null")
    
    if [[ "$webkit_installed" == *"not installed"* || -z "$webkit_installed" ]]; then
        echo "RHEL ${rhel_version},webkit2gtk3 not installed,SAFE - Package not installed"
        return
    fi
    
    # Check for installed security patches for webkit2gtk3
    local installed_patches=$(run_ssh_command "$ip" "$user" "$use_key" "
        sudo yum updateinfo list --security installed 2>/dev/null | grep webkit2gtk3 | awk '{print \$1}' | sort -u | tr '\\n' ' ' || echo 'Unable to check'
    ")
    
    # Define expected patches based on RHEL version
    local expected_patch=""
    if [[ "$rhel_version" == "8" ]]; then
        expected_patch="RHSA-2024:2982"
    elif [[ "$rhel_version" == "9" ]]; then
        expected_patch="RHSA-2024:2126"
    fi
    
    # Determine status
    local status="VULNERABLE"
    if [[ "$installed_patches" == "Unable to check" ]]; then
        status="UNABLE TO VERIFY"
    elif [[ "$installed_patches" == *"$expected_patch"* ]]; then
        status="PATCHED"
    elif [[ -n "$installed_patches" ]]; then
        status="PARTIALLY PATCHED - Check if correct patch applied"
    else
        status="VULNERABLE - No security patches found"
    fi
    
    echo "RHEL ${rhel_version},${installed_patches:-None},${status}"
}

# Fungsi untuk memeriksa CVE-2021-20325 (httpd mod_proxy dan mod_session)
check_cve_2021_20325() {
    local ip=$1
    local user=$2
    local use_key=$3
    
    # Check RHEL version (specifically RHEL 8.5)
    local rhel_version=$(run_ssh_command "$ip" "$user" "$use_key" "
        if [[ -f /etc/redhat-release ]]; then
            cat /etc/redhat-release | grep -oE 'release [0-9]+\.[0-9]+' | cut -d' ' -f2
        else
            echo 'Not RHEL'
        fi
    ")
    
    # Check httpd version
    local httpd_version=$(run_ssh_command "$ip" "$user" "$use_key" "
        if rpm -q httpd &>/dev/null; then
            rpm -q httpd | head -1
        else
            echo 'Not Installed'
        fi
    ")
    
    local vulnerable_status="Unknown"
    local overall_status="Unknown"
    
    # Only RHEL 8.5 with httpd 2.4 is affected
    if [[ "$rhel_version" == "8.5" ]]; then
        if [[ "$httpd_version" != "Not Installed" && "$httpd_version" == *"httpd-2.4"* ]]; then
            # Check if mod_proxy and mod_session modules are enabled
            local mod_proxy=$(run_ssh_command "$ip" "$user" "$use_key" "
                httpd -M 2>/dev/null | grep -i proxy || echo 'not loaded'
            ")
            local mod_session=$(run_ssh_command "$ip" "$user" "$use_key" "
                httpd -M 2>/dev/null | grep -i session || echo 'not loaded'
            ")
            
            if [[ "$mod_proxy" != "not loaded" || "$mod_session" != "not loaded" ]]; then
                vulnerable_status="VULNERABLE"
                overall_status="VULNERABLE - RHEL 8.5 with httpd 2.4 and affected modules"
            else
                vulnerable_status="Not Vulnerable"
                overall_status="SAFE - Modules not loaded"
            fi
        elif [[ "$httpd_version" == "Not Installed" ]]; then
            vulnerable_status="Not Installed"
            overall_status="SAFE - httpd not installed"
        else
            vulnerable_status="Not Vulnerable"
            overall_status="SAFE - Not httpd 2.4"
        fi
    else
        vulnerable_status="Not Affected"
        overall_status="SAFE - Not RHEL 8.5"
    fi
    
    echo "${httpd_version:-Unknown},${rhel_version:-Unknown},${vulnerable_status},${overall_status}"
}

# Fungsi untuk memeriksa semua CVE vulnerabilities
check_all_vulnerabilities() {
    local ip=$1
    local success=false
    
    # Loop untuk user dan method autentikasi
    for user in "${users[@]}"; do
        for use_key in "true" "false"; do
            if [[ "$use_key" == "true" ]]; then
                auth_method="SSH Key"
                log_message "Memeriksa IP: $ip dengan user: $user (menggunakan SSH key)"
            else
                auth_method="Password"
                log_message "Memeriksa IP: $ip dengan user: $user (tanpa SSH key)"
            fi
            
            # Test koneksi SSH
            if ! test_ssh_connection "$ip" "$user" "$use_key"; then
                log_message "Koneksi gagal/timeout ke $ip dengan user $user ($auth_method)"
                continue
            fi
            
            log_message "Koneksi berhasil ke $ip dengan user $user ($auth_method)"
            
            # Get OS version
            local os_version=$(run_ssh_command "$ip" "$user" "$use_key" "
                if [[ -f /etc/redhat-release ]]; then
                    cat /etc/redhat-release
                elif [[ -f /etc/os-release ]]; then
                    grep PRETTY_NAME /etc/os-release | cut -d'=' -f2 | tr -d '\"'
                else
                    uname -a
                fi
            ")
            
            # Initialize CSV row
            local csv_row="$ip,$user,$auth_method,${os_version:-Unknown},Success"
            
            # Check each CVE if enabled
            if [[ "$CHECK_CVE_2019_15504" == "true" ]]; then
                log_message "Checking CVE-2019-15504/15505 (Kernel USB)..."
                local cve_2019_result=$(check_cve_2019_15504 "$ip" "$user" "$use_key")
                csv_row="$csv_row,$cve_2019_result"
                echo -e "${CYAN}  CVE-2019-15504/15505:${NC} $cve_2019_result"
            fi
            
            if [[ "$CHECK_CVE_2007_4559" == "true" ]]; then
                log_message "Checking CVE-2007-4559 (Python tarfile)..."
                local cve_2007_result=$(check_cve_2007_4559 "$ip" "$user" "$use_key")
                csv_row="$csv_row,$cve_2007_result"
                echo -e "${YELLOW}  CVE-2007-4559:${NC} $cve_2007_result"
            fi
            
            if [[ "$CHECK_CVE_2014_1745" == "true" ]]; then
                log_message "Checking CVE-2014-1745 (webkit2gtk3)..."
                local cve_2014_result=$(check_cve_2014_1745 "$ip" "$user" "$use_key")
                csv_row="$csv_row,$cve_2014_result"
                echo -e "${PURPLE}  CVE-2014-1745:${NC} $cve_2014_result"
            fi
            
            if [[ "$CHECK_CVE_2021_20325" == "true" ]]; then
                log_message "Checking CVE-2021-20325 (httpd)..."
                local cve_2021_result=$(check_cve_2021_20325 "$ip" "$user" "$use_key")
                csv_row="$csv_row,$cve_2021_result"
                echo -e "${RED}  CVE-2021-20325:${NC} $cve_2021_result"
            fi
            
            # Write to CSV
            echo "$csv_row" >> "$output_file"
            
            # Output ke console dengan warna
            echo -e "${GREEN}✓${NC} $ip - User: $user ($auth_method)"
            echo -e "  OS: ${os_version:-Unknown}"
            echo ""
            
            success=true
            break 2  # Keluar dari kedua loop jika berhasil
        done
    done
    
    # Jika semua user gagal, tetap tulis output
    if [[ "$success" == false ]]; then
        echo -e "${RED}✗${NC} $ip - Timeout atau tidak bisa terhubung dengan semua kombinasi user/auth"
        local failed_row="$ip,All Users Failed,Timeout/Failed,-,Connection Failed"
        
        # Add empty columns for disabled CVE checks
        if [[ "$CHECK_CVE_2019_15504" == "true" ]]; then
            failed_row="$failed_row,-,-,-"
        fi
        if [[ "$CHECK_CVE_2007_4559" == "true" ]]; then
            failed_row="$failed_row,-,-,-"
        fi
        if [[ "$CHECK_CVE_2014_1745" == "true" ]]; then
            failed_row="$failed_row,-,-,-"
        fi
        if [[ "$CHECK_CVE_2021_20325" == "true" ]]; then
            failed_row="$failed_row,-,-,-,-"
        fi
        
        echo "$failed_row" >> "$output_file"
    fi
}

# Fungsi untuk membuat ringkasan hasil
create_summary() {
    log_message "Membuat ringkasan hasil..."
    
    local total_hosts=$(tail -n +2 "$output_file" | wc -l)
    local successful_connections=$(grep "Success" "$output_file" | wc -l)
    local failed_connections=$(grep "Connection Failed" "$output_file" | wc -l)
    local skipped_hosts=$(grep "Skipped" "$output_file" | wc -l)
    
    echo ""
    echo "========================================"
    echo "           RINGKASAN HASIL"
    echo "========================================"
    echo "Total hosts yang diperiksa: $total_hosts"
    echo "Koneksi berhasil: $successful_connections"
    echo "Koneksi gagal: $failed_connections"
    echo "Hosts yang di-skip: $skipped_hosts"
    echo ""
    
    # CVE-specific summaries
    if [[ "$CHECK_CVE_2019_15504" == "true" ]]; then
        local kernel_vulnerable=$(grep "VULNERABLE" "$output_file" | grep -c "cve_2019")
        echo "CVE-2019-15504/15505 (Kernel USB):"
        echo "  - Vulnerable hosts: $kernel_vulnerable"
    fi
    
    if [[ "$CHECK_CVE_2007_4559" == "true" ]]; then
        local python_vulnerable=$(grep "VULNERABLE" "$output_file" | grep -c "cve_2007")
        echo "CVE-2007-4559 (Python tarfile):"
        echo "  - Vulnerable hosts: $python_vulnerable"
    fi
        if [[ "$CHECK_CVE_2014_1745" == "true" ]]; then
        local webkit_vulnerable=$(grep "VULNERABLE" "$output_file" | grep -c "cve_2014")
        echo "CVE-2014-1745 (webkit2gtk3):"
        echo "  - Vulnerable hosts: $webkit_vulnerable"
    fi

    if [[ "$CHECK_CVE_2021_20325" == "true" ]]; then
        local httpd_vulnerable=$(grep "VULNERABLE" "$output_file" | grep -c "cve_2021")
        echo "CVE-2021-20325 (httpd mod_proxy/mod_session):"
        echo "  - Vulnerable hosts: $httpd_vulnerable"
    fi

    echo ""
    echo "Hasil lengkap disimpan di: $output_file"
    echo "Pemeriksaan selesai pada $(date)"
}

main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Show configuration
    show_configuration
    
    # Initialize output file
    initialize_output_file
    
    # Check if instances file exists
    if [[ ! -f "$instances_file" ]]; then
        log_message "${RED}ERROR:${NC} File instances '$instances_file' tidak ditemukan"
        exit 1
    fi
    
    log_message "Memulai pemeriksaan CVE vulnerabilities..."
    
    # Read all IPs from file into array
    mapfile -t ips < <(grep -v '^[[:space:]]*#' "$instances_file" | grep -v '^$' | awk '{$1=$1};1')
    
    # Process each IP in the array
    for ip in "${ips[@]}"; do
        # Validate IP format
        if [[ ! "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            log_message "${YELLOW}WARNING:${NC} Format IP tidak valid: '$ip' - akan di-skip"
            echo "$ip,Invalid IP Format,Skipped" >> "$output_file"
            continue
        fi
        
        # Check if IP should be skipped based on range
        if should_skip_ip "$ip"; then
            log_message "${CYAN}INFO:${NC} IP $ip di-skip berdasarkan konfigurasi range"
            echo "$ip,Skipped by IP Range Configuration,Skipped" >> "$output_file"
            continue
        fi
        
        # Check vulnerabilities for this IP
        check_all_vulnerabilities "$ip"
    done
    
    # Create summary report
    create_summary
    
    exit 0
}

# Panggil fungsi main dengan semua argument
main "$@"