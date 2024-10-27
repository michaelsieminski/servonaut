#!/bin/bash

cmd_help() {
    cat <<"EOF"
--------                                                                                  
@@@@@@@@.                                                                            
@@@@@@@@.      sssss   eeeeee  rrrrrr   v   v   ooooo   n   nn  aaaaaa  u   uu  ttttt
@@@@@@@@.     ss      ee      rr   rr  v   v  oo   oo  nn  nn  aa  aa  u   uu    tt
@@@@@@@@.      ssss   eeeeee  rrrrrr    v v   oo   oo  nnnnnn  aaaaaaa u   uu    tt
@%====#@.        sss  ee      rr  rr     v    oo   oo  nn  nn  aa   aa u   uu    tt
@#    +@.     sssss    eeeeee rr   rr    v     ooooo   nn  nn  aa   aa  uuuuu    tt
@#....+@.                                                                                  
********                                                                                 
EOF

    echo -e "\nWelcome to Servonaut - Your one-click Nuxt deployment solution!\n"

    echo "Available commands:"
    echo "  servonaut setup     - Setup Servonaut on your server"
    echo "  servonaut update    - Update Servonaut to the latest version"
    echo "  servonaut help      - Show this help message"
    echo "  servonaut env list  - List all environment variables"
    echo "  servonaut env add   - Add an environment variable"
    echo "  servonaut env del   - Remove an environment variable"

    echo -e "\nFor more information, visit: https://github.com/michaelsieminski/servonaut"
}
