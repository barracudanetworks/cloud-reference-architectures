#!/bin/bash
echo "
##############################################################################################################
#  _                         
# |_) _  __ __ _  _     _| _ 
# |_)(_| |  | (_|(_ |_|(_|(_|
#
# Deployment of CUDALAB EU configuration in Microsoft Azure using Terraform and Ansible
#
##############################################################################################################
"

# Stop running when command returns error
set -e

STATE="terraform.tfstate"

while getopts "bg" option; do
    case "${option}" in
        b) DEPLOYMENTCOLOR="blue" ;;
        g) DEPLOYMENTCOLOR="green" ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# Generate SSH key
echo ""
echo "==> Generate and verify SSH key location and permissions"
echo ""
SSH_KEY_DATA=`cat output/ssh_key.pub`
DOWNLOADSECUREFILE1_SECUREFILEPATH="output/ssh_key"
chmod 700 `dirname $DOWNLOADSECUREFILE1_SECUREFILEPATH`
chmod 600 $DOWNLOADSECUREFILE1_SECUREFILEPATH
export DOWNLOADSECUREFILE1_SECUREFILEPATH

cd terraform/
echo ""
echo "==> Starting Terraform deployment"
echo ""

echo ""
echo "==> Terraform init"
echo ""
terraform init

echo ""
echo "==> Terraform workspace [$DEPLOYMENTCOLOR]"
echo ""
terraform workspace list
terraform workspace select $DEPLOYMENTCOLOR || terraform workspace new $DEPLOYMENTCOLOR

echo ""
echo "==> Terraform destroy"
echo ""
terraform destroy -var "DEPLOYMENTCOLOR=$DEPLOYMENTCOLOR" \
                  -var "PREFIX=x" \
                  -var "PASSWORD=x" \
                  -var "DB_PASSWORD=x" \
                  -var "SSH_KEY_DATA=x" \
                  -var "LOCATION=x" \
                  -auto-approve 
