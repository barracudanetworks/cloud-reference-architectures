##############################################################################################################
#  _                         
# |_) _  __ __ _  _     _| _ 
# |_)(_| |  | (_|(_ |_|(_|(_|
#                                                    
# Terraform configuration for Blue/Green deployment: Networking
#
##############################################################################################################

resource "azurerm_resource_group" "resourcegroupvnet" {
  name     = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-RG-VNET"
  location = "${var.LOCATION}"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-VNET"
  address_space       = ["${var.vnet[var.DEPLOYMENTCOLOR]}"]
  location            = "${azurerm_resource_group.resourcegroupvnet.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroupvnet.name}"
}

resource "azurerm_subnet" "subnet1" {
  name                 = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-SUBNET-CGF"
  resource_group_name  = "${azurerm_resource_group.resourcegroupvnet.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "${var.subnet_cgf[var.DEPLOYMENTCOLOR]}"
}

resource "azurerm_subnet" "subnet2" {
  name                 = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-SUBNET-WAF"
  resource_group_name  = "${azurerm_resource_group.resourcegroupvnet.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "${var.subnet_waf[var.DEPLOYMENTCOLOR]}"
  route_table_id       = "${azurerm_route_table.wafroute.id}"
}

resource "azurerm_subnet" "subnet3" {
  name                 = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-SUBNET-WEB"
  resource_group_name  = "${azurerm_resource_group.resourcegroupvnet.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "${var.subnet_web[var.DEPLOYMENTCOLOR]}"
  route_table_id       = "${azurerm_route_table.webroute.id}"
}

resource "azurerm_subnet" "subnet4" {
  name                 = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-SUBNET-DB"
  resource_group_name  = "${azurerm_resource_group.resourcegroupvnet.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "${var.subnet_db[var.DEPLOYMENTCOLOR]}"
  route_table_id       = "${azurerm_route_table.dbroute.id}"
}

resource "azurerm_route_table" "webroute" {
  name                = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-RT-WEB"
  location            = "${var.LOCATION}"
  resource_group_name = "${azurerm_resource_group.resourcegroupvnet.name}"

  route {
    name                   = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-WebToInternet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${var.cgf_a_ipaddress[var.DEPLOYMENTCOLOR]}"
  }

  route {
    name                   = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-WebToWAF"
    address_prefix         = "${var.subnet_waf[var.DEPLOYMENTCOLOR]}"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${var.cgf_a_ipaddress[var.DEPLOYMENTCOLOR]}"
  }

  route {
    name                   = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-WebToDB"
    address_prefix         = "${var.subnet_db[var.DEPLOYMENTCOLOR]}"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${var.cgf_a_ipaddress[var.DEPLOYMENTCOLOR]}"
  }
}

resource "azurerm_route_table" "wafroute" {
  name                = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-RT-WAF"
  location            = "${var.LOCATION}"
  resource_group_name = "${azurerm_resource_group.resourcegroupvnet.name}"

  route {
    name                   = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-WAFToWEB"
    address_prefix         = "${var.subnet_web[var.DEPLOYMENTCOLOR]}"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${var.cgf_a_ipaddress[var.DEPLOYMENTCOLOR]}"
  }

  route {
    name                   = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-WAFToDB"
    address_prefix         = "${var.subnet_db[var.DEPLOYMENTCOLOR]}"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${var.cgf_a_ipaddress[var.DEPLOYMENTCOLOR]}"
  }

  route {
    name                   = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-WAFToDEV"
    address_prefix         = "172.16.250.0/24"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${var.cgf_a_ipaddress[var.DEPLOYMENTCOLOR]}"
  }
}

resource "azurerm_route_table" "dbroute" {
  name                = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-RT-DB"
  location            = "${var.LOCATION}"
  resource_group_name = "${azurerm_resource_group.resourcegroupvnet.name}"

  route {
    name                   = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-DBToInternet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${var.cgf_a_ipaddress[var.DEPLOYMENTCOLOR]}"
  }

  route {
    name                   = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-DBToWAF"
    address_prefix         = "${var.subnet_waf[var.DEPLOYMENTCOLOR]}"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${var.cgf_a_ipaddress[var.DEPLOYMENTCOLOR]}"
  }

  route {
    name                   = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-DBToWEB"
    address_prefix         = "${var.subnet_web[var.DEPLOYMENTCOLOR]}"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${var.cgf_a_ipaddress[var.DEPLOYMENTCOLOR]}"
  }
}
