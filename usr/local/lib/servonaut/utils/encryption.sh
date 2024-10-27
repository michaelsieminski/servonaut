#!/bin/bash

generate_safe_password() {
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24
}
