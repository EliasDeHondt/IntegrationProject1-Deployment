#!/bin/bash
############################
# @author Elias De Hondt   #
# @see https://eliasdh.com #
# @since 01/03/2024        #
############################
# FUNCTIE: This script is used to test the horizontal scaling of the application

for ((i=1; i<=10; i++)); do 
    (for i in {1..1000}; do 
        for j in {1..1000}; do 
            curl -s "https://codeforge.eliasdh.com" >/dev/null &
        done; 
    sleep 1; 
    done; wait) & 
done
# Or
stress --cpu 4 --timeout 600000