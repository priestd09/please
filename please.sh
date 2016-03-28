#!/usr/bin/env bash

#
# Please - An almost-polite and human automatic project creator for vagrant boxes.
# By Jehan Fillat <contact@jehanfillat.com>
#
# Version 0.1
#
#
# This script automates the creation & deletion of new sites on webservers
#
# Copyright (C) 2016 Jehan Fillat
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.1.6.0
#
version_number=0.1

# Defining colors
if [[ ! -z $(which tput 2>/dev/null) ]]; then
	normal=$(tput sgr0)
	bold=$(tput bold)
	red=$(tput setaf 1;tput bold)
	green=$(tput setaf 2;tput bold)
	yellow=$(tput setaf 3;tput bold)
    blue=$(tput setaf 4;tput bold)
	magenta=$(tput setaf 5;tput bold)
	cyan=$(tput setaf 6;tput bold)
    white=$(tput setaf 7;tput bold)
    error_bg=$(tput setab 1)
fi

about() {
	cat <<ABOUT
	${cyan}

    ██████╗ ██╗     ███████╗ █████╗ ███████╗███████╗
    ██╔══██╗██║     ██╔════╝██╔══██╗██╔════╝██╔════╝
    ██████╔╝██║     █████╗  ███████║███████╗█████╗  
    ██╔═══╝ ██║     ██╔══╝  ██╔══██║╚════██║██╔══╝  
    ██║     ███████╗███████╗██║  ██║███████║███████╗
    ╚═╝     ╚══════╝╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝                  

    A polite and human automatic project creator for vagrant boxes.
    Author : Jehan Fillat <contact@jehanfillat.com>
    GitHub : https://github.com/JehanApathia
    
    ${normal}
ABOUT
}

mkdomain() {
   
    echo $'\n'"${bold}Please wait. ${normal}I'm creating the Directory for $sitename..."
    
    if mkdir -p public/$sitename ; then
        echo "$sitename" > public/$sitename/custom-hosts
        echo "${green}Hooray!${normal} Directory created successfully."$'\n'
    fi
    
}

mkvhost() {
    
    echo "${bold}Hold on please. ${normal}I'm creating the Virtual Host config for $sitename..."
    if vagrant ssh -- -q -t "sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/$sitename.conf" ; then
        vagrant ssh -- -q -t "sudo sed -i s,'#ServerName www.example.com','ServerName $sitename',g /etc/apache2/sites-available/$sitename.conf"
        vagrant ssh -- -q -t "sudo sed -i s,/var/www/public,/var/www/public/$sitename,g /etc/apache2/sites-available/$sitename.conf"
        vagrant ssh -- -q -t "sudo a2ensite $sitename.conf > /dev/null 2>&1"
        echo "${green}Hooray!${normal} Virtual Host is ready."$'\n'
    else
        echo "${error_bg}${bold}${white}Oops!${normal} I was unable to create the database. Exiting."$'\n'
        exit
    fi
    
}

vagrant_reboot() {
    
    echo "${bold}The final step! ${normal}I'm restarting your vagrant box..."
    if vagrant reload --provision ; then
        echo "${green}Hooray!${normal} I've worked correctly, for once. Vagrant Box's up again!"$'\n'
    fi
    
}

ask_sitename() {
    
    # accept the name of our website
    sitename=
    while [[ $sitename = "" ]]; do
        read -e -p "Site name (with extension): " sitename
    done
    
}

create_domain() {
    
    echo $'\n'"${bold}Please, give me some informations for your new domain${normal}"
    
    ask_sitename
    
    if [ -d "public/$sitename" ]; then 
    
        echo ""
        echo "${bold}${error_bg}${white}$sitename already exists.${normal} ${bold}Don't be a sadistic, leave these fellows here, it's freezing cold out there!${normal}"
        echo ""
        exit
        
    else
    
        default_site_db="N" 
        read -e -p "Do you want me to create an empty MySQL database ? [y/$default_site_db]: " site_db
        site_db=${site_db:-$default_site_db}
        
        echo ""
        echo "${bold}${blue}Please, double-check your informations before I begin to work. ${normal}"
        echo ""
        echo "${bold} Site name : ${cyan}$sitename ${normal}"
        [ $site_db = "y" ] && echo "${bold} Create a database : ${green} Yes please.${normal}" || echo "${bold} Create a database : ${bold}${red} No thanks.${normal}"
        echo ""
        
        # add a simple yes/no confirmation before we proceed
        read -e -p "Do you want me to run the installation procedure? [Y/n]: " run

        # if the user didn't say no, then go ahead an install
        if [ "$run" == n ] ; then
            exit
        else
    
            mkdomain
            
            mkvhost
            
            if [ $site_db = "y" ] ; then
                echo "${bold}Please wait. ${normal}Creating database for $sitename..."
                if vagrant ssh -- -q -t "mysqladmin -u root create $sitename" ; then
                    echo "${green}Hooray!${normal} Database $sitename created successfully."$'\n'
                else
                    echo "${error_bg}${bold}${white}Oops!${normal} I was unable to create the database. Exiting."$'\n'
                    exit
                fi
            fi
            
            vagrant_reboot
            
            echo "================================================================="
            echo ""
            echo "${bold}   Your Domain is ${bold}${cyan}ready${normal}!"
            echo ""
            echo "   Enjoy your new website : ${cyan}http://$sitename ${normal}"
            echo ""
            echo "================================================================="
            echo ""

        fi
        
    fi
        
      
}

create_wordpress() {
    
    echo $'\n'"${bold}${blue}Please, give me some informations for your new WordPress installation ${normal}"
    
    ask_sitename
    
    if [ -d "public/$sitename" ]; then 
        echo ""
        echo "${bold}${red}$sitename already exists.${bold} ${bold}Don't be a sadistic, leave these fellows here, it's freezing cold out there!${bold}"
        echo ""
        exit
    else
    
        username=
        while [[ $username = "" ]]; do
            read -e -p "Admin Username: " username
        done
        password=
        while [[ $password = "" ]]; do
            read -s -p "Admin Password: " password
        done
        echo ""
        email=
        while [[ $email = "" ]]; do
            read -e -p "Admin Email address: " email
        done
        
        default_wp_cli="Y" 
            read -e -p "Maybe you want to update wp-cli ? [$default_wp_cli/n]: " wp_cli
        wp_cli=${wp_cli:-$default_wp_cli}
        
        echo ""
        echo "${bold}${blue}Please, double-check your informations before I begin to work. ${normal}"
        echo ""
        echo "${bold} Site name : ${cyan}$sitename${normal}"
        echo "${bold} Admin Username : ${cyan}$username${normal}"
        echo "${bold} Admin Email address : ${cyan}$email${normal}"
        [ $wp_cli = "Y" ] && echo "${bold} Update WP-CLI : ${bold}${green} Yes please.${normal}" || echo "${bold} Update WP-CLI : ${bold}${red} No thanks.${normal}"
        echo ""
        
        # add a simple yes/no confirmation before we proceed
        read -e -p "Do you want me to run the installation procedure? [Y/n]: " run

        # if the user didn't say no, then go ahead an install
        if [ "$run" == n ] ; then
            exit
        else

            mkdomain

            mkvhost
            
            if [ "$wp_cli" = "Y" ] ; then
            
                echo "${bold}I'm updating WP-CLI, please wait...${normal}"
                if vagrant ssh -- -q "curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" ; then
                    vagrant ssh -- -q "sudo chmod +x wp-cli.phar"
                    vagrant ssh -- -q "sudo mv wp-cli.phar /usr/local/bin/wp"
                    echo "${bold}${green}WP-CLI updated successfully!${normal}"
                else
                    echo "${bold}${red}Sorry... I wasn't able to update WP-CLI...${normal}"
                fi           
            
            else
            
                if ! vagrant ssh -- -q "[ -f /usr/local/bin/wp ] && echo '${bold}WP-CLI install found, going on.${normal}'" ; then
                
                    [ "$wp_cli" = "n" ] && echo "${bold}You're a little sadistic, you wanted me to install & configure WordPress without WP-CLI! ${normal}" 
                    echo "${bold}I'm installing WP-CLI, please wait...${normal}"
                    if vagrant ssh -- -q "curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" ; then
                        vagrant ssh -- -q "sudo chmod +x wp-cli.phar"
                        vagrant ssh -- -q "sudo mv wp-cli.phar /usr/local/bin/wp"
                        echo "${bold}${green}WP-CLI installed successfully!${normal}"
                    else
                        echo "${bold}${red}Sorry... I wasn't able to install WP-CLI...${normal}"
                    fi 
                    
                fi
                
                # download the WordPress core file
                vagrant ssh -- -q "wp core download --path='/var/www/public/$sitename'"
                
                # create the wp-config file with our standard setup
                vagrant ssh -- -q "wp core config --path='/var/www/public/$sitename' --dbname=$sitename --dbuser=root --dbpass=root --extra-php <<PHP
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
PHP"

                echo $'\n'"${bold}Please wait. I'm creating the WordPress database${normal}"
                vagrant ssh -- -q "wp db create --path='/var/www/public/$sitename'"
                echo $'\n'"${bold}I know this is getting boring${normal}, but I have almost finished! I'm installing WordPress right now..."
                vagrant ssh -- -q "wp core install --url='http://$sitename' --title='$sitename' --admin_user='$username' --admin_password='$password' --admin_email='$email' --path='/var/www/public/$sitename' --skip-email"
                
                # set pretty urls
                vagrant ssh -- -q "wp rewrite structure '/%postname%/' --hard --path='/var/www/public/$sitename'"
                vagrant ssh -- -q "wp rewrite flush --hard --path='/var/www/public/$sitename'"
                
                # delete akismet and hello dolly
                vagrant ssh -- -q "wp plugin delete akismet --path='/var/www/public/$sitename'"
                vagrant ssh -- -q "wp plugin delete hello --path='/var/www/public/$sitename'"
                
                echo ""
                vagrant_reboot
                
                echo "================================================================="
                echo ""
                echo "${bold}Your WordPress is ${cyan}ready${normal}!"
                echo ""
                echo "Enjoy your new website : ${blue}http://$sitename ${normal}"
                echo "Head to your WordPress admin : ${blue}http://$sitename/wp-admin ${normal}"
                echo ""
                echo "================================================================="
                echo ""

            fi
            
        fi
        
    fi
    
}

create_symfony() {
    
    echo ""
    echo "${bold}${cyan}Please, give me some informations for your new Symfony project ${normal}"
    
    ask_sitename
    
    if [ -d "public/$sitename" ]; then 
        echo ""
        echo "${bold}${red}$sitename already exists.${normal} ${bold}Don't be a sadistic, leave these fellows here, it's freezing cold out there!${normal}"
        echo ""
        exit
    else
    
        default_symfony_version="lts"
        read -e -p "Which version do you want to install ? (number or [$default_symfony_version]): " symfony_version
        symfony_version=${symfony_version:-$default_symfony_version}
        
        if vagrant ssh -- -q "grep -q \;date.timezone '/etc/php5/apache2/php.ini'"; then
            default_configure_timezone="Y" 
            read -e -p "Configure your date.timezone in php.ini? [$default_configure_timezone/n]: " configure_timezone
            configure_timezone=${configure_timezone:-$default_configure_timezone}
        else
            configure_timezone="configured"
        fi
        
        if [[ $configure_timezone = "Y" ]] ; then
            timezone=
            while [[ $timezone = "" ]]; do
                default_timezone="Europe/Paris"
                read -e -p "What timezone would you want to set? [e.g. $default_timezone]: " timezone
                timezone=${timezone:-$default_timezone}
            done
        fi
        
        xdebug=$(php -m | grep -i xdebug)
        if ! vagrant ssh -- -q "[[ -z '$xdebug' ]] && echo 'It seems to me that xdebug is installed, going on.'" ; then
            default_xdebug_install="Y"
            read -e -p "I see that the php xdebug extension is not installed, do you want me to install it? [$default_xdebug_install/n]: " xdebug_install
            xdebug_install=${xdebug_install:-$default_xdebug_install}
        else
            xdebug_install="installed"
        fi
        
        apc=$(php -m | grep apc) 
        if ! vagrant ssh -- -q "[[ -z '$apc' ]] && echo 'It seems to me that APC is installed, going on.'" ; then
            default_apc_install="Y"
            read -e -p "APC Cache doesn't seems to installed, do you want me to install it? [$default_apc_install/n]: " apc_install
            apc_install=${apc_install:-$default_apc_install}
        else
            apc_install="installed"
        fi
        
        echo ""
        echo "${blue}Please, double-check your informations before I begin to work. ${normal}"
        echo ""
        echo "${bold} Site name : ${cyan}$sitename${normal}"
        echo "${bold} Symfony version : ${cyan}$symfony_version${normal}"
        if [ $xdebug_install = "Y" ] ; then 
            echo "${bold} Install PHP xdebug : ${bold}${green}Yes please.${normal}"
        elif [ $xdebug_install = "n" ] ; then
            echo "${bold} Install PHP xdebug : ${bold}${red} No thanks.${normal}"
        else 
            echo "${bold} Install PHP xdebug : ${bold}${blue}Already installed.${normal}"
        fi
        
        if [ $apc_install = "Y" ] ; then
            echo "${bold} Install php APC : ${bold}${green}Yes please.${normal}"
        elif [ $apc_install = "n" ] ; then
            echo "${bold} Install php APC : ${bold}${red} No thanks.${normal}"
        else
            echo "${bold} Install php APC : ${bold}${blue}Already installed.${normal}"
        fi
        
        if [ $configure_timezone = "Y" ] ; then
            echo "${bold} Configure timezone : ${bold}${green}Yes please.${normal}"
        elif [ $configure_timezone = "n" ] ; then
            echo "${bold} Configure timezone : ${bold}${red}No thanks.${normal}"
        else
            echo "${bold} Configure timezone : ${bold}${blue}Already configured.${normal}"
        fi
        if [ $configure_timezone = "Y" ] ; then
            echo "${bold} Chosen timezone : ${bold}${green}$timezone${normal}"
        else
            echo ""
        fi
        
        # add a simple yes/no confirmation before we proceed
        read -e -p "Do you want me to run the installation procedure? [Y/n]: " run

        # if the user didn't say no, then go ahead an install
        if [ "$run" == n ] ; then
            exit
        else
        
            if [ $configure_timezone = "Y" ] ; then
                # Set the date.timezone in /etc/php5/cli/php.ini to avoid error
                vagrant ssh -- -q "sudo sed -i s,'\;date.timezone =','date.timezone = $timezone',g /etc/php5/apache2/php.ini"
                vagrant ssh -- -q "sudo sed -i s,'\;date.timezone =','date.timezone = $timezone',g /etc/php5/cli/php.ini"
            fi
            
            if ! vagrant ssh -- -q "[ ! -f '/usr/local/bin/symfony' ]" ; then
                echo $'\n'"${bold}Symfony does not seems to be installed. ${normal}Begin installation..."
                vagrant ssh -- -q "sudo curl -LsS https://symfony.com/installer -o /usr/local/bin/symfony"
                vagrant ssh -- -q "sudo chmod a+x /usr/local/bin/symfony"
                echo "${bold}${green}Hooray! ${bold}I managed to install Symfony on your Vagrant Box without ruining everything!${normal}"$'\n'
            fi
            
            if [ $xdebug_install = "Y" ] ; then
                echo "${bold}I'm installing xdebug. ${normal}Please wait a few seconds..."
                vagrant ssh -- -q "sudo apt-get update -qq"
                vagrant ssh -- -q "sudo apt-get install php5-xdebug"
                echo "${bold}${green}Hooray! ${bold}xdebug is installed!${normal}"$'\n'
            fi
            
            if [ $apc_install = "Y" ] ; then
                echo "${bold}I'm installing APC. ${normal}Please wait a few seconds..."
                vagrant ssh -- -q "sudo apt-get update -qq"
                vagrant ssh -- -q "sudo apt-get install php-apc"
                echo "${bold}${green}Hooray! ${bold}APC is installed!${normal}"$'\n'
            fi
            
            echo "${bold}Please wait. ${normal}I'm creating your new Symfony project..."
            vagrant ssh -- -q "(cd /var/www/public && symfony new $sitename $symfony_version)"
            vagrant ssh -- -q "echo '$sitename' > /var/www/public/$sitename/custom-hosts"
            
            echo "${bold}Hold on please. ${normal}I'm creating the Virtual Host config for $sitename..."
            if vagrant ssh -- -q -t "sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/$sitename.conf" ; then
                vagrant ssh -- -q -t "sudo sed -i s,'#ServerName www.example.com','ServerName $sitename',g /etc/apache2/sites-available/$sitename.conf"
                vagrant ssh -- -q -t "sudo sed -i s,/var/www/public,/var/www/public/$sitename/web,g /etc/apache2/sites-available/$sitename.conf"
                vagrant ssh -- -q -t "sudo a2ensite $sitename.conf > /dev/null 2>&1"
                echo "${green}Hooray!${normal} Virtual Host is ready."$'\n'
            else
                echo "${error_bg}${bold}${white}Oops!${normal} I was unable to create the database. Exiting."$'\n'
                exit
            fi
            
            echo "${bold}Hold on, be quiet. ${normal}I'm cracking the code of the vault, full access incoming..."
            vagrant ssh -- -q "sudo sed -i 's/'\''127.0.0.1'\''/'\''127.0.0.1'\'', '\''192.168.33.1'\''/g' /var/www/public/test.dev/web/app_dev.php"
            vagrant ssh -- -q "sudo sed -i 's/'\''127.0.0.1'\''/'\''127.0.0.1'\'',\n'\''192.168.33.1'\''/g' /var/www/public/test.dev/web/config.php"
            
            vagrant_reboot
            
            echo "================================================================="
            echo ""
            echo "${bold}Your Symfony project is ${cyan}ready${normal}!"
            echo ""
            echo "Enjoy your new website : ${blue}http://$sitename ${normal}"
            echo ""
            echo "================================================================="
            echo ""
        
        fi
    
    fi
    
}

create_angular() {
    
    echo ""
    echo "${bold}${cyan}Please, give me some informations for your new Angular2 App ${normal}"
    
    ask_sitename
    
    default_node_npm_update="N"
        read -e -p "Maybe you want to update node & npm while you go grab a coffee? [y/N]: " node_npm_update
    node_npm_update=${node_npm_update:-$default_node_npm_update}
    
    default_tsc="Y"
        read -e -p "Run Angular2 TypeScript Compiler in watch mode right after installation? [Y/n]: " tsc
    tsc=${tsc:-$default_tsc}
    
    echo ""
    echo "${blue}Please, double-check your informations before I begin to work. ${normal}"
    echo ""
    echo "${bold} Site name : ${cyan}$sitename ${normal}"
    [ $node_npm_update = "y" ] && echo "${bold} Update node & npm : ${green} Yes please.${normal}" || echo "${bold} Update node & npm : ${red} No thanks.${normal}"
    [ $tsc = "Y" ] && echo "${bold} Run Angular2 TypeScript compiler : ${green} Yes please.${normal}" || echo "${bold} Run Angular2 TypeScript compiler : ${red} No thanks.${normal}"
    echo ""
    
    # add a simple yes/no confirmation before we proceed
    read -e -p "Do you want me to run the installation procedure? [Y/n]: " run

    # if the user didn't say no, then go ahead an install
    if [ "$run" == n ] ; then
        exit
    else

        echo $'\n'"${bold}Please wait. ${normal}I'm importing a quickstart Angular2 App from GitHub Repo in $sitename directory..."
        if vagrant ssh -- -q "git clone https://github.com/angular/quickstart /var/www/public/$sitename" ; then
            vagrant ssh -- -q "sudo sed -i 's/Angular 2 QuickStart/$sitename/g' /var/www/public/$sitename/index.html"
            # THE FOLLOWING LINE IS A FIX FOR THE "ReferenceError: System is not defined" ERROR
            #vagrant ssh -- -q "sudo sed -i 's,node_modules/systemjs/dist/system.src.js,https://code.angularjs.org/tools/system.js,g' /var/www/public/test.dev/index.html"
            # THE FOLLOWING LINE IS A FIX FOR THIS ERROR : http://stackoverflow.com/questions/33332394/angular-2-typescript-cant-find-names/35514492#35514492
            # vagrant ssh -- -q "sed -i -e '1i///<reference path='../node_modules/angular2/typings/browser.d.ts'/>\' /var/www/public/$sitename/app/main.ts"
            vagrant ssh -- -q "sudo sed -i 's/angular2-quickstart/$sitename/g' /var/www/public/$sitename/package.json"
            vagrant ssh -- -q "echo $sitename > /var/www/public/$sitename/custom-hosts"
            vagrant ssh -- -q "echo '${bold}${green}Hooray!${normal} Angular2 App imported successfully. It's a wonderful little girl! Take care of her or it's gonna be veeery very bad for you. Please.'$'\n'"
        fi

        mkvhost
        
        if [ $node_npm_update = "Y" ] ; then
            if vagrant ssh -- -q "sudo npm cache clean -f" ; then
                echo "${bold}sudo npm cache clean -f : ${bold}${green}ok ${normal}"
            fi
            if vagrant ssh -- -q "sudo npm install -g n" ; then
                echo "${bold}sudo npm install -g n : ${bold}${green}ok ${normal}"
            fi
            if vagrant ssh -- -q "sudo n stable" ; then
                echo "${bold}sudo n stable : ${bold}${green}ok ${normal}"
            fi
            if vagrant ssh -- -q "sudo n stable" ; then
            echo "${bold}sudo npm install npm -g : ${bold}${green}ok ${normal}"
            fi
        fi
        
        echo "${bold}I'm doing a possibly-not-so-quick \"npm install\"${normal}, sorry about that."
        vagrant ssh -- -q "(cd /var/www/public/$sitename && npm install  --ignore-scripts --quiet)"
        vagrant ssh -- -q "(cd /var/www/public/$sitename && npm run typings install)"
        echo "${bold}${green}Hooray! ${normal}${bold}I finally finished to do the npm-install! Let's have a drink together.${normal}"$'\n'
        
        vagrant_reboot

        echo "================================================================="
        echo ""
        echo "${bold}Your new Angular2 App is ${bold}${cyan}ready${normal}!"
        echo ""
        echo "Enjoy it here : ${blue}http://$sitename${normal}"
        echo ""
        echo "================================================================="
        echo ""
        
        if [ $tsc == "Y" ] ; then
            echo "${bold}I launch the TypeScript Compiler in watch mode immediately${normal}, as you requested."
            vagrant ssh -- -q "(cd /var/www/public/$sitename && npm run tsc:w)"
        fi

    fi
    
}

create_laravel() {
    
    echo ""
    echo "${bold}${cyan}Please, give me some informations for your new Laravel project ${normal}"
    
    ask_sitename
    
    default_composer_update="N"
        read -e -p "Maybe you want to update composer while you go grab a cup of tea? [y/N]: " composer_update
    composer_update=${composer_update:-$default_composer_update}
    
    echo ""
    echo "${blue}Please, double-check your informations before I begin to work. ${normal}"
    echo ""
    echo "${bold} Site name : ${cyan}$sitename ${normal}"
    [ $composer_update = "y" ] && echo "${bold} Update Composer : ${green} Yes please.${normal}" || echo "${bold} Update Composer : ${red} No thanks.${normal}"
    echo ""
    
    # add a simple yes/no confirmation before we proceed
    read -e -p "Do you want me to run the installation procedure? [Y/n]: " run

    # if the user didn't say no, then go ahead an install
    if [ "$run" == n ] ; then
    exit
    else
    
        if [ $composer_update = "y" ] ; then 
            echo $'\n'"${bold}Updating Composer. ${normal}"
            if vagrant ssh -- -q "sudo /usr/local/bin/composer self-update" ; then
                echo "${bold}${green}Hooray! ${normal}${bold}Composer's up and runnin', baby. ${normal}"$'\n'
            else
                echo "${error_bg}${bold}${white}Oops! ${normal}${bold}Something went wrong, I don't know where, I don't know why. ${normal}"$'\n'
            fi
                
        fi
        
        echo "${bold}Hold on please. ${normal}I'm creating the Virtual Host config for $sitename..."
        if vagrant ssh -- -q -t "sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/$sitename.conf" ; then
            vagrant ssh -- -q -t "sudo sed -i s,'#ServerName www.example.com','ServerName $sitename',g /etc/apache2/sites-available/$sitename.conf"
            vagrant ssh -- -q -t "sudo sed -i s,/var/www/public,/var/www/public/$sitename/public,g /etc/apache2/sites-available/$sitename.conf"
            vagrant ssh -- -q -t "sudo a2ensite $sitename.conf > /dev/null 2>&1"
            echo "${green}Hooray!${normal} Virtual Host is ready."$'\n'
        else
            echo "${error_bg}${bold}${white}Oops!${normal} I was unable to create the database. Exiting."$'\n'
            exit
        fi
        
        echo "${bold}And now, the grand final (it was long, hu?), Laravel itself.${normal}"
        if vagrant ssh -- -q "(cd /var/www/public && composer create-project --prefer-dist laravel/laravel $sitename)" ; then
            echo "$sitename" > public/$sitename/custom-hosts
            echo "${bold}${green}Hooray! ${normal}${bold}I made it! Laravel is installed!. ${normal}"$'\n'
        else
            echo "${error_bg}${bold}${white}Oops! ${normal}${bold}I messed up everything... I wasn't able to install Laravel... I'm a loser...${normal}"$'\n'
        fi
        
        vagrant_reboot

        echo "================================================================="
        echo ""
        echo "${bold}Your new Laravel project is ${bold}${cyan}ready${normal}!"
        echo ""
        echo "Enjoy it here : ${blue}http://$sitename${normal}"
        echo ""
        echo "================================================================="
        echo ""
    
    fi
    
}

create() {
    
    echo "${cyan}${bold}"
    echo "Please select the type of project you want me to create :${normal}"
    PS3=$'\n'"Please enter your choice: "
    options=("Simple Domain" "WordPress" "Symfony" "Angular2" "Laravel" "Quit")
    echo ""
    select opt in "${options[@]}"
    do
        case $opt in
            "Simple Domain")
                create_domain
                break
                ;;
            "WordPress")
                create_wordpress
                break
                ;;
            "Symfony")
                create_symfony
                break
                ;;
            "Angular2")
                create_angular
                break
                ;;
            "Laravel")
                create_laravel
                break
                ;;
            "Quit")
                break
                ;;
            *) echo invalid option;;
        esac
    done
    
}

delete() {
    
    echo ""
    echo "${bold}Alright. ${normal}I hope it's not my fault..."
    echo ""
    
    sitename=
    while [[ $sitename = "" ]]; do
        read -e -p "Which site do you want me to delete (don't forget the extension): " sitename
    done
    
    # checking if folder exists, if not : returns error message, if yes, going on
    if [ ! -d "public/$sitename" ]; then 
        echo ""
        echo "${bold}${red}$sitename doesn't exists.${normal} ${bold}Screw you guys, I'm going home!${normal}"
        echo ""
        exit
    else

        read -e -p "Are you sure? You will throw $sitename into limbo. His soul will be lost forever. [Y/n]: " run

        # if the user didn't say no, then go ahead and remove
        if [ "$run" == n ] ; then
            exit
        else
            
            echo ""
            echo ""
            echo "-------------------------------------------------"
            echo "${bold}† $sitename ut requiescant in pace. †${normal}"
            echo "-------------------------------------------------"
            echo ""
            echo ""
            
            echo "${bold}Please wait, ${normal}I'm checking if there's a database to remove."
            if ! vagrant ssh -- -q "mysqlshow '$sitename' > /dev/null 2>&1 && echo 'Hey! I found it!'" ; then
                echo "${bold}No database found. ${normal}I'm going on."$'\n'
            else 
                echo "${bold}Hold on please, ${normal}I'm removing database for $sitename..."
                if vagrant ssh -- -q "mysqladmin -u root drop $sitename" ; then
                    echo "${bold}${green}Hooray!${normal} database removed"$'\n'
                else
                    echo "${error_bg}${bold}${white}Oops!${normal} I was unable to delete the database. Exiting."$'\n'
                    exit
                fi
            fi

            echo "${bold}Please wait. ${normal}I'm removing $sitename directory ..."
            if rm -R public/$sitename ; then
                echo "${bold}${green}Hooray!${normal} Directory removed successfully."$'\n'
            else
                echo "${error_bg}${bold}${white}Oops!${normal} I was unable to delete the directory. Exiting."$'\n'
                exit
            fi

            echo "${bold}Hold on please, ${normal}I'm deleting $sitename Virtual Host..."
            if vagrant ssh -- -q "sudo a2dissite $sitename.conf > /dev/null 2>&1" ; then
                vagrant ssh -- -q "sudo rm /etc/apache2/sites-available/$sitename.conf"
                echo "${bold}${green}Hooray!${normal} Virtual Host deleted"$'\n'
            else
                echo "${error_bg}${bold}${white}Oops!${normal} I was unable to delete the Virtual Host. Exiting."$'\n'
                exit
            fi

            vagrant_reboot
            
            echo "Your $sitename was sucessfully ${bold}${cyan}erased${normal}!"$'\n'

        fi
        
    fi
    
}

main() {
	
    if [ -z "$1" ]; then
	    about
	fi
    
    if [ "$1" = "create" ]; then
    	create
    fi
    
    if [ "$1" = "delete" ]; then
    	delete
    fi

}

if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
	main "$@"
fi