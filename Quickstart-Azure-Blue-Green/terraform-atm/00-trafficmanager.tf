##############################################################################################################
#  _                         
# |_) _  __ __ _  _     _| _ 
# |_)(_| |  | (_|(_ |_|(_|(_|
#                                                    
# Terraform configuration for Blue/Green deployment: Azure Traffic Manager
#
##############################################################################################################

# Prefix for all resources created for this deployment in Microsoft Azure
variable "PREFIX" {
  description = "The shortened abbreviation to represent deployment that will go on the front of some resources."
}

variable "DEPLOYMENTCOLOR" {
  description = "Which version of the deployment are we deploying"
}

variable "TMDNSNAME" {
  description = "DNS Name for the Azure Traffic Manager"
}

variable "LOCATION" {
  description = "The name of the resource group in which to create the virtual network."
}

##############################################################################################################
# Microsoft Azure Storage Account for storage of Terraform state file
##############################################################################################################

terraform {
  required_version = ">= 0.11"
}

##############################################################################################################
# Microsoft Azure Service Principle information for deployment
##############################################################################################################

#variable "AZURE_SUBSCRIPTION_ID" {}
#variable "AZURE_CLIENT_ID" {}
#variable "AZURE_CLIENT_SECRET" {}
#variable "AZURE_TENANT_ID" {}

provider "azurerm" {
#  subscription_id = "${var.AZURE_SUBSCRIPTION_ID}"
#  client_id       = "${var.AZURE_CLIENT_ID}"
#  client_secret   = "${var.AZURE_CLIENT_SECRET}"
#  tenant_id       = "${var.AZURE_TENANT_ID}"
}

##############################################################################################################
# Static variables
##############################################################################################################

locals {
  DEPLOYMENTOTHERCOLOR = "${var.DEPLOYMENTCOLOR == "blue" ? "green" : "blue"}"
}

##############################################################################################################
# Azure Traffic Manager
##############################################################################################################

resource "azurerm_resource_group" "resourcegrouptm" {
  name     = "${var.PREFIX}-RG-TM"
  location = "${var.LOCATION}"
}

resource "azurerm_traffic_manager_profile" "trafficmanagerprofile" {
  name                = "${var.PREFIX}-TM-PROFILE"
  resource_group_name = "${azurerm_resource_group.resourcegrouptm.name}"

  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "${var.TMDNSNAME}"
    ttl           = 100
  }

  monitor_config {
    protocol = "https"
    port     = 443
    path     = "/"
  }

  tags {
    environment = "quickstart"
    vendor = "Barracuda Networks"
  }
}

resource "azurerm_traffic_manager_endpoint" "trafficmanagerendpointblue" {
  name                = "${var.PREFIX}-TM-ENDPOINT-BLUE"
  resource_group_name = "${azurerm_resource_group.resourcegrouptm.name}"
  profile_name        = "${azurerm_traffic_manager_profile.trafficmanagerprofile.name}"
  target              = "${format("%s-blue-waf-pip.%s.cloudapp.azure.com", lower(var.PREFIX), var.LOCATION)}"
  type                = "externalEndpoints"
  endpoint_status     = "${var.DEPLOYMENTCOLOR == "blue" ? "Enabled" : "Disabled"}"
}

resource "azurerm_traffic_manager_endpoint" "trafficmanagerendpointgreen" {
  name                = "${var.PREFIX}-TM-ENDPOINT-GREEN"
  resource_group_name = "${azurerm_resource_group.resourcegrouptm.name}"
  profile_name        = "${azurerm_traffic_manager_profile.trafficmanagerprofile.name}"
  target              = "${format("%s-green-waf-pip.%s.cloudapp.azure.com", lower(var.PREFIX), var.LOCATION)}"
  type                = "externalEndpoints"
  endpoint_status     = "${var.DEPLOYMENTCOLOR == "green" ? "Enabled" : "Disabled"}"
}
