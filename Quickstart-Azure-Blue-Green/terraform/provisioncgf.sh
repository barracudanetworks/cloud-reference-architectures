#!/bin/bash
{
echo "Starting Barracuda CloudGen Firewall bootstrap"
/opb/cloud-setmip ${cgf_ipaddr} ${cgf_mask} ${cgf_gw}
/opb/cloud-enable-rest
/opb/cloud-restore-license -f
} > /tmp/provision.log 2>&1