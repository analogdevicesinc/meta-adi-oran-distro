#!/bin/bash

interface=$1
address=$2

#Fallback configuration in the event that an interface cannot obtain a DHCP lease from server

if ! ip addr show dev "$interface" | grep -q "inet "; then
    ip addr add "$address" dev "$interface" >> /dev/null
fi