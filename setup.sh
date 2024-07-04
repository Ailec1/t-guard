#!/bin/bash

while true; do
    OPTION=$(whiptail --title "Main Menu" --menu "Choose an option:" 20 70 13 \
                    "1" "Update System and Install Prerequisites" \
                    "2" "Install Docker" \
                    "3" "Install Wazuh (SIEM)" \
                    "4" "Install Shuffle (SOAR)" \
                    "5" "Install DFIR-IRIS (Incident Response Platform)" \
                    "6" "Setup Simulation and POC" \
                    "7" "Install MISP" \
                    "8" "Setup IRIS <-> Wazuh Integration" \
                    "9" "Setup MISP <-> Wazuh Integration" \
                    "10" "Setup AbuseIPDB <-> Wazuh Integration" \
                    "11" "Show Status" \
                    "12" "Restart Wazuh" \
                    "13" "Delete All Containers, Images, Volumes, and Networks" 3>&1 1>&2 2>&3)
    # Script version 1.0 updated 15 November 2023
    # Depending on the chosen option, execute the corresponding command
    case $OPTION in
    1)
        sudo apt-get update -y
        sudo apt-get upgrade -y
        # sudo apt-get install wget curl nano git unzip -y
        sudo apt-get install wget curl nano git unzip ca-certificates -y
        ;;
    2)
        # Check if Docker is installed
        if command -v docker > /dev/null; then
            echo "Docker is already installed."
        else
            # # Install Docker
            # curl -fsSL https://get.docker.com -o get-docker.sh
            # sudo sh get-docker.sh
            # sudo systemctl enable docker.service && sudo systemctl enable containerd.service

            # Install Docker
            # Add Docker's official GPG key:
            sudo install -m 0755 -d /etc/apt/keyrings
            sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
            sudo chmod a+r /etc/apt/keyrings/docker.asc
            # Add the repository to Apt sources:
            echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
            $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            # Install Docker Packages
            sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        fi
        ;;
    3)
        cd wazuh
        sudo sysctl -w vm.max_map_count=262144
        sudo docker network create shared-network
        sudo docker compose -f generate-indexer-certs.yml run --rm generator
        sudo docker compose up -d
        ;;
    4)
        cd shuffle
        sudo docker compose up -d
        ;;
    5)
        cd iris-web
        sudo docker compose build
        sudo docker compose up -d
        ;;
    6)
        wget -c https://github.com/danielmiessler/SecLists/archive/master.zip -O SecList.zip \
        && unzip SecList.zip \
        && rm -f SecList.zip
        cd examples/poc-wazuh/brute-force
        sudo docker compose build
        sudo docker compose up -d
        ;;
    7)
        cd misp
        IP=$(curl -s ip.me -4)
        sed -i "s|BASE_URL=.*|BASE_URL='https://$IP:1443'|" template.env
        cp template.env .env
        sudo docker compose up -d
        ;;
    8)
        cp wazuh/custom-integrations/custom-iris.py /var/lib/docker/volumes/wazuh_wazuh_integrations/_data/custom-iris.py
        sudo docker exec -ti wazuh-wazuh.manager-1 chown root:wazuh /var/ossec/integrations/custom-iris.py
        sudo docker exec -ti wazuh-wazuh.manager-1 chmod 750 /var/ossec/integrations/custom-iris.py
        sudo docker exec -ti wazuh-wazuh.manager-1 apt update -y
        sudo docker exec -ti wazuh-wazuh.manager-1 apt install python3-pip -y
        sudo docker exec -ti wazuh-wazuh.manager-1 pip3 install requests
        cd wazuh && sudo docker compose restart
        ;;
    9)
        cp wazuh/custom-integrations/custom-misp.py /var/lib/docker/volumes/wazuh_wazuh_integrations/_data/custom-misp.py
        sudo docker exec -ti wazuh-wazuh.manager-1 chown root:wazuh /var/ossec/integrations/custom-misp.py
        sudo docker exec -ti wazuh-wazuh.manager-1 chmod 750 /var/ossec/integrations/custom-misp.py
        # cp wazuh/custom-integrations/local_rules.xml /var/lib/docker/volumes/wazuh_wazuh_etc/_data/rules/local_rules.xml
        # sudo docker exec -ti wazuh-wazuh.manager-1 chown wazuh:wazuh /var/ossec/etc/rules/local_rules.xml
        # sudo docker exec -ti wazuh-wazuh.manager-1 chmod 550 /var/ossec/etc/rules/local_rules.xml
        # cp wazuh/custom-integrations/local_decoder.xml /var/lib/docker/volumes/wazuh_wazuh_etc/_data/decoders/local_decoder.xml
        # sudo docker exec -ti wazuh-wazuh.manager-1 chown wazuh:wazuh /var/ossec/etc/decoders/local_decoder.xml
        # sudo docker exec -ti wazuh-wazuh.manager-1 chmod 550 /var/ossec/etc/decoders/local_decoder.xml
        cd wazuh && sudo docker compose restart
        ;;
    10)
        cp wazuh/custom-integrations/custom-abuseipdb.py /var/lib/docker/volumes/wazuh_wazuh_integrations/_data/custom-abuseipdb.py
        sudo docker exec -ti wazuh-wazuh.manager-1 chown root:wazuh /var/ossec/integrations/custom-abuseipdb.py
        sudo docker exec -ti wazuh-wazuh.manager-1 chmod 750 /var/ossec/integrations/custom-abuseipdb.py
        cd wazuh && sudo docker compose restart
        ;;
    11)
        sudo docker ps
        ;;

    12)
        cd wazuh
        sudo docker compose restart
        ;;

    13)
        # Stop all containers
        sudo docker stop $(sudo docker ps -a -q)
        # Delete all containers
        sudo docker rm -f $(sudo docker ps -a -q)
        # Delete all images
        sudo docker rmi -f $(sudo docker images -q)
        # Delete all volumes
        sudo docker volume rm $(sudo docker volume ls -q)
        # Delete all networks
        sudo docker network rm $(sudo docker network ls -q)
        # Delete Docker
        sudo systemctl stop docker.socket
        sudo systemctl disable docker.service && sudo systemctl disable containerd.service
        sudo apt-get purge docker-ce docker-ce-cli containerd.io -y
        sudo rm -rf /var/lib/docker
        ;;
esac
    # Give option to go back to the previous menu or exit
    if (whiptail --title "Exit" --yesno "Do you want to exit the script?" 8 78); then
        break
    else
        continue
    fi
done
