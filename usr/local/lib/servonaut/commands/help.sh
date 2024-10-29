#!/bin/bash

cmd_help() {
    cat <<"EOF"
--------                                                                                  
@@@@@@@@.                                                                            
@@@@@@@@.      sssss   eeeeee  rrrrrr   vv   vv   ooooo   n   nn  aaaaaaa  uu   uu  tttttt
@@@@@@@@.     ss      ee       rr   rr  vv   vv  oo   oo  nn  nn  aa   aa  uu   uu    tt
@@@@@@@@.      ssss   eeeeee   rrrrrr   vv   vv  oo   oo  nnn nn  aaaaaaa  uu   uu    tt
@%====#@.         ss  ee       rr  rr    vv vv   oo   oo  nn nnn  aa   aa  uu   uu    tt
@#    +@.     sssss    eeeeee  rr   rr    vvv     ooooo   nn  nn  aa   aa   uuuuu     tt
@#....+@.                                                                                  
********                                                                                 
EOF

    echo -e "\nWelcome to Servonaut - Your one-click deployment solution!\n"

    echo "Available commands:"
    echo "  servonaut setup     - Setup Servonaut on your server"
    echo "  servonaut update    - Update Servonaut to the latest version"
    echo "  servonaut help      - Show this help message"
    echo "  servonaut env list  - List all environment variables"
    echo "  servonaut env add   - Add an environment variable"
    echo "  servonaut env del   - Remove an environment variable"
    echo "  servonaut status    - Check the status of your deployment"

    echo -e "\nFor more information, visit: https://github.com/michaelsieminski/servonaut"
}
