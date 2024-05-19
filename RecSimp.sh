#!/bin/bash

clear
# Colors for output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
WHITE='\033[0;37m'
STOP='\033[0m'

echo -e '''
    ____            _____ _               
   / __ \___  _____/ ___/(_)___ ___  ____ 
  / /_/ / _ \/ ___/\__ \/ / __ `__ \/ __ \
 / _, _/  __/ /__ ___/ / / / / / / / /_/ /
/_/ |_|\___/\___//____/_/_/ /_/ /_/ .___/\033[1;31m v1.0.3\033[0m
                                 /_/
        https://t.me/RootHarpy
[-]Team Bitsec - The closer you look, The less you see.[-]      
'''
function find_subdomains {
    local domain=$1
    echo -e "${GREEN}Finding subdomains for $domain ...${CYAN}"
    curl -s "https://crt.sh/?q=${domain}&output=json" | jq -r '.[].name_value' | grep -Po '(\w+\.\w+\.\w+)$' | sort -u
    echo -e "${STOP}"
}
function find_cve_poc {
    local cve_id=$1
    echo -e "${GREEN}Searching for PoCs for $cve_id ...${CYAN}"
    curl -s "https://poc-in-github.motikan2010.net/api/v1/?cve_id=$cve_id" | jq | grep html_url | awk -F '"' '{print $4}'
    echo -e "${STOP}"
}
function check_clickjacking {
    local url=$1
    echo -e "${GREEN}Checking for clickjacking on $url ...${CYAN}"

    if [[ ! $url == http* ]]; then
        url="https://$url"
    fi

    local response=$(curl -I -s --max-time 3 "$url")
    local status_code=$(echo "$response" | grep HTTP | awk '{print $2}')
    if [[ $status_code -eq 200 ]]; then
        if [[ $response != *"X-Frame-Options"* ]] && [[ $response != *"Content-Security-Policy"* ]]; then
            echo -e "${RED}[+] ${WHITE}$url is ${RED}Vulnerable"
        else
            echo -e "${CYAN}[-] ${WHITE}$url is ${CYAN}NOT Vulnerable"
        fi
    else
        echo -e "${YELLOW}[!] ${WHITE}$url returned status code other than 200"
    fi
}

function list_vulnerable_site {
    local url=$1
    echo "$url" >> Vulnerable.txt
}
function display_help {
    echo -e "${CYAN}Options:${WHITE}"
    echo -e "  ${CYAN}-o 1${WHITE}  Subdomain enumeration"
    echo -e "  ${CYAN}-o 2${WHITE}  CVE POC (Proof of Concept) finding"
    echo -e "  ${CYAN}-o 3${WHITE}  Clickjacking detection"
    echo -e "${YELLOW}Usage: $0 -o <option> -d <domain> -c <cve_id> -f <file>${WHITE}"
    exit 0
}
function main {
    while getopts "o:d:c:f:h" flag; do
        case "${flag}" in
            o) option=${OPTARG};;
            d) domain=${OPTARG};;
            c) cve_id=${OPTARG};;
            f) file=${OPTARG};;
            h) display_help;;
            ?) echo "Invalid option. Use -h for help."
               exit 1;;
        esac
    done

    if [[ -z "$option" ]]; then
        display_help
        exit 1
    fi

    case $option in
        1)
            if [[ -z "$domain" ]]; then
                echo "Domain not provided. Use -d for domain."
                exit 1
            fi
            find_subdomains "$domain"
            ;;
        2)
            if [[ -z "$cve_id" ]]; then
                echo "CVE ID not provided. Use -c for CVE ID."
                exit 1
            fi
            find_cve_poc "$cve_id"
            ;;
        3)
            if [[ -n "$domain" ]]; then
                check_clickjacking "$domain"
            elif [[ -n "$file" ]]; then
                sites=$(cat "$file")
                for site in $sites; do
                    check_clickjacking "$site"
                done
            else
                echo "URL or file not provided. Use -d for URL or -f for file."
                exit 1
            fi
            ;;
    esac
}

main "$@"
