#!/bin/sh

# Wrapper script for SWUpdate to trigger factory reset

case "$1" in
    preinst)
        echo "Pre-install: preparing for factory reset"
        exit 0
        ;;
    postinst)
        echo "Post-install: executing factory reset"
        /usr/sbin/factory-reset.sh
        exit 0
        ;;
    postfailure)
        echo "SWUpdate failed, skipping factory reset"
        exit 0
        ;;
    *)
        exit 0
        ;;
esac
