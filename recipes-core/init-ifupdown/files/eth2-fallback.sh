#!/bin/bash

#Fallback configuration in the event that eth2 cannot obtain a DHCP lease from server

if ! ip addr show dev eth2 | grep -q "inet "; then
    ip addr add 192.168.1.33/24 dev eth2 >> /dev/null
fi