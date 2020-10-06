#!/bin/bash

# Color variables
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"


#######################################################
##  START Main
#######################################################
main() {
    rootCheck
    displayIntro

    cd /tmp

    installEpel
    updateOs
    installEssentialPackages
    installAndConfigureApache
}
#######################################################
##  END Main
#######################################################


#######################################################
##  START Utilities
#######################################################

# Check if the script is run as root or user with superuser privilege
rootCheck() {
    ROOT_UID=0
    SUCCESS=0
    
    if [ "$UID" -ne "$ROOT_UID" ]; then
        echo "Sorry must be in root to run this script"
        exit 65
    fi
}

displayIntro() {
    clear >$(tty)
    
    # Initial prompt
    echo -e "${RED}MOODLE INSTALLER${NC}"
    printf "\n"
    echo "This script will install LAPP stack and Moodle LMS."
    printf "\n\n"
    read -p "Press enter to continue or CTRL+C to exit"
}

installEpel() {
    clear >$(tty)
    echo -e "\n${GREEN}Installing Extra Packages for Enterprise Linux (EPEL)...${NC}"
    
    # Install epel-release
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY*
    dnf -y install epel-release
}

updateOs() {
    clear >$(tty)
    echo -e "\n${GREEN}Updating CentOS...${NC}"

    # Update CentOS
    dnf -y update && dnf -y upgrade
}

installEssentialPackages() {
    # Install Python 3
    dnf -y install python3
    alternatives --set python "$(which python3)"
    
    # Install essential packages
    dnf -y install wget unzip git bashtop
}

installAndConfigureApache() {
    # Install Apache
    dnf -y install httpd httpd-tools
    dnf -y install mod_ssl
    
    systemctl enable httpd
    systemctl start httpd

    # Configure SELinux for Apache
    setsebool httpd_can_network_connect true
    setsebool httpd_can_network_connect_db true


    # Configure firewall
    firewall-cmd --zone=public --permanent --add-service=http
    firewall-cmd --zone=public --permanent --add-service=https
    firewall-cmd --reload
}

installAndConfigurePostgresql() {
    # Install PostgreSQL 10
    dnf -y install @postgres:10
    dnf -y install postgresql-contrib

    systemctl enable postgresql
    systemctl start postgresql

    # Backup pg_hba.conf
    cp /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf.bak

    # Initialize database
    runuser -l postgres -c "psql -c \"CREATE USER moodleuser WITH PASSWORD 'yourpassword';\""
    runuser -l postgres -c "psql -c \"CREATE DATABASE moodle WITH OWNER moodleuser;\""

    echo -e "Installed PostgreSQL: \n$(postgres --version)"
}

installAndConfigurePhp() {
    dnf -y install php \
    php-opcache php-gd php-curl php-mysqlnd php-mbstring \
    php-openssl php-xmlrpc php-soap php-zip php-simplexml \
    php-spl php-pcre php-dom php-xml php-intl php-json \
    php-pgsql php-pdo_pgsql

    echo -e "Installed PHP: \n$(php --version)"
}

#######################################################
##  END Utilities
#######################################################

main "$@"; exit
