# Moodle Installer

## Introduction

This script is for installing Moodle LMS on LAPP stack (Linux, Apache, PostreSQL, PHP) in CentOS 8. It will also create a database and database user to be used by Moodle. 


## How To Use

1. Download the source code or use `git clone` if you already have `git` installed.
    ```
    # git clone https://github.com/rashidrazak/moodle-installer.git
    ```
2. Put it in `/root` directory, or any other directory. Doesn't really matter.
    ```
    # cp -r moodle-installer /root
    ```
3. Copy the `.env-sample` to a new file and rename it as `.env`.
    ```
    # cd /root/moodle-installer
    # cp .env-sample .env
    ```
4. Fill in the details in `.env` file correctly.
5. Make `install_lapp.sh` executable:
    ```
    # chmod +x install_lapp.sh
    ```
6. Run the script to install LAPP and Moodle LMS.
    ```
    # ./install_lapp.sh
    ```
7. When the script is done, you may visit your URL to see the newly installed Moodle.


## Warning!!

- This script has been tested on a freshly provisioned Linode VPS running CentOS 8.
- This script is only meant for provisioning Moodle LMS and LAPP stack in an empty server.
- DO NOT use it if you have any other things installed on your server. This script is meant for getting Moodle up and running quickly on a fresh server.


## Installed Packages

This script will install the followings:

|  Packages  | Version |  Remarks |
|:----------:|:-------:|:--------:|
| Apache     | 2.4.46  | httpd    |
| PostgreSQL | 10.6    | psql     |
| PHP        | 7.2     | php      |
| Moodle     | 3.9.2   |          |


## Todos

- [x] Install Apache
- [x] Install PostgreSQL
- [x] Install PHP
- [x] Install Moodle LMS
- [x] Create a new user with superuser privilege
- [ ] Make script more dynamic with checking for pre-installed packages
- [ ] Support for Apache virtual host
- [ ] Support for SSL and auto SSL installation
- [ ] Make single-file executable from curl