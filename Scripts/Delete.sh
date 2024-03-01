#!/bin/bash
######################
# Van Elias De Hondt #
######################
# FUNCTIE: This is de script to delete the GCloud infrastructure.
reset='\e[0m'
rood='\e[0;31m'
blauw='\e[0;34m'
groen='\e[0;32m'

function error_exit() { # Functie: Error afhandeling
  echo -e "Error: ${rood}$1${reset}"
  exit 1
}

[ "$EUID" -ne 0 ] && error_exit "Script must be run as root, e.g., using sudo." 