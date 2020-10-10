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

    # Set curent directory
    CURRENT_DIR=$(pwd)

    displayIntro
    readVar


    installEpel
    updateOs
    installEssentialPackages
    installAndConfigureApache
    installAndConfigurePostgresql
    installAndConfigurePhp
    downloadAndInstallMoodle
    createSudoUser
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

readVar() {
    set -o allexport; source .env; set +o allexport
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
    clear >$(tty)
    echo -e "\n${GREEN}Installing essential packages...${NC}"

    # Install Python 3
    dnf -y install python3
    alternatives --set python "$(which python3)"
    
    # Install essential packages
    dnf -y install wget unzip git bashtop rsync
}

installAndConfigureApache() {
    clear >$(tty)
    echo -e "\n${GREEN}Installing Apache...${NC}"

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
    clear >$(tty)
    echo -e "\n${GREEN}Installing PostgreSQL 10...${NC}"

    # Install PostgreSQL 10
    dnf -y install @postgresql:10
    dnf -y install postgresql-contrib

    postgresql-setup initdb
    systemctl enable postgresql
    systemctl start postgresql

    # Backup pg_hba.conf
    cp /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf.bak
    chown postgres:postgres /var/lib/pgsql/data/pg_hba.conf.bak

    # Initialize database
    runuser -l postgres -c "psql -c \"CREATE USER $PGSQL_MOODLE_USER WITH PASSWORD '$PGSQL_MOODLE_USER_PASSWORD';\""
    runuser -l postgres -c "psql -c \"CREATE DATABASE $PGSQL_MOODLE_DATABASE WITH OWNER $PGSQL_MOODLE_USER ENCODING 'UTF8' LC_COLLATE='en_US.UTF-8' LC_CTYPE='en_US.UTF-8' TEMPLATE=template0;\""

    echo -e "Installed PostgreSQL: \n$(postgres --version)"

    systemctl stop postgresql
    cat "$(pwd)"/config/pg_hba.conf > /var/lib/pgsql/data/pg_hba.conf
    systemctl start postgresql

    # rm /var/lib/pgsql/data/pg_hba.conf
    # mv $(pwd)/config/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf
    # chown postgres:postgres /var/lib/pgsql/data/pg_hba.conf
    # chmod 600 /var/lib/pgsql/data/pg_hba.conf
    # systemctl restart postgresql
    sleep 3
}

installAndConfigurePhp() {
    clear >$(tty)
    echo -e "\n${GREEN}Installing PHP 7.2...${NC}"

    # Install PHP
    dnf -y install php \
    php-opcache php-gd php-curl php-mysqlnd php-mbstring \
    php-openssl php-xmlrpc php-soap php-zip php-simplexml \
    php-spl php-pcre php-dom php-xml php-intl php-json \
    php-pgsql php-pdo_pgsql

    echo -e "Installed PHP: \n$(php --version)"
    sleep 3
}

downloadAndInstallMoodle() {
    clear >$(tty)
    echo -e "\n${GREEN}Installing Moodle LMS...${NC}"

    git clone -b $MOODLE_STABLE_BRANCH git://git.moodle.org/moodle.git
    rsync -avP $(pwd)/moodle/ /var/www/html/

    mkdir -p /opt/moodle/moodledata
    chown -R apache:apache /opt/moodle
    chmod -R 777 /opt/moodle

    chcon -t httpd_sys_content_t /opt/moodle/moodledata -R
    chcon -t httpd_sys_rw_content_t /opt/moodle/moodledata -R

    chown -R apache:apache /var/www/html
    cd /var/www/html/admin/cli

    runuser -u apache $(which php) install.php -- \
        --chmod="$MOODLE_DIRECTORYPERMISSIONS" \
        --lang="$MOODLE_LANG" \
        --wwwroot="$MOODLE_WWWROOT" \
        --dataroot="$MOODLE_DATAROOT" \
        --dbtype="$MOODLE_DBTYPE" \
        --dbhost="$MOODLE_DBHOST" \
        --dbname="$PGSQL_MOODLE_DATABASE" \
        --dbuser="$PGSQL_MOODLE_USER" \
        --dbpass="$PGSQL_MOODLE_USER_PASSWORD" \
        --dbport="$MOODLE_DBPORT" \
        --prefix="$MOODLE_PREFIX" \
        --fullname="$MOODLE_FULLNAME" \
        --shortname="$MOODLE_SHORTNAME" \
        --summary="$MOODLE_SUMMARY" \
        --adminuser="$MOODLE_ADMINUSER" \
        --adminpass="$MOODLE_ADMINPASS" \
        --adminemail="$MOODLE_ADMINEMAIL" \
        --non-interactive \
        --agree-license \
        --allow-unstable

    chown -R root:root /var/www/html
    chmod -R 755 /var/www/html

    systemctl restart postgresql
    systemctl restart httpd
    cd $CURRENT_DIR
    sleep 3
}

createSudoUser() {
    useradd "$SUDO_USER_USERNAME"
    echo $SUDO_USER_PASSWORD | passwd $SUDO_USER_USERNAME --stdin
    usermod -aG wheel "$SUDO_USER_USERNAME"
}

#######################################################
##  END Utilities
#######################################################

main "$@"; exit
