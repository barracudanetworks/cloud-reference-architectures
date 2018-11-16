##############################################################################################################
#  _                         
# |_) _  __ __ _  _     _| _ 
# |_)(_| |  | (_|(_ |_|(_|(_|
#                                                    
# Terraform configuration for Blue/Green deployment: Variables
#
##############################################################################################################

# Prefix for all resources created for this deployment in Microsoft Azure
variable "PREFIX" {
  description = "The shortened abbreviation to represent deployment that will go on the front of some resources."
}

variable "DEPLOYMENTCOLOR" {
  description = "Selecting the correct deployment."
  default     = "blue"
}

variable "LOCATION" {
  description = "The name of the resource group in which to create the virtual network."
}

# Static password used for CGF, WAF and SQL database
variable "PASSWORD" {}

# Static password used for SQL database
variable "DB_PASSWORD" {}

# SSH public key used for the backend web and sql server
variable "SSH_KEY_DATA" {}

##############################################################################################################
# Barracuda License type selection
##############################################################################################################

# This variable defined the type of CGF and billing used. For BYOL you can use pool licenses for repeated deployments.
variable "CGFIMAGESKU" {
  description = "Azure Marketplace Image SKU hourly (PAYG) or byol (Bring your own license)"
  default = "hourly"
}

# This variable defined the type of WAF and billing used. For BYOL you can use pool licenses for repeated deployments.
variable "WAFIMAGESKU" {
  description = "Azure Marketplace Image SKU hourly (PAYG) or byol (Bring your own license)"
  default = "hourly"
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

variable "vnet" {
  type        = "map"
  description = ""

  default = {
    "blue"  = "172.16.100.0/24"
    "green" = "172.16.101.0/24"
  }
}

variable "subnet_cgf" {
  type        = "map"
  description = ""

  default = {
    "blue"  = "172.16.100.0/26"
    "green" = "172.16.101.0/26"
  }
}

variable "subnet_waf" {
  type        = "map"
  description = ""

  default = {
    "blue"  = "172.16.100.64/26"
    "green" = "172.16.101.64/26"
  }
}

variable "subnet_web" {
  type        = "map"
  description = ""

  default = {
    "blue"  = "172.16.100.128/26"
    "green" = "172.16.101.128/26"
  }
}

variable "subnet_db" {
  type        = "map"
  description = ""

  default = {
    "blue"  = "172.16.100.192/26"
    "green" = "172.16.101.192/26"
  }
}

variable "cgf_a_ipaddress" {
  type        = "map"
  description = ""

  default = {
    "blue"  = "172.16.100.10"
    "green" = "172.16.101.10"
  }
}

variable "cgf_subnetmask" {
  type        = "map"
  description = ""

  default = {
    "blue"  = "26"
    "green" = "26"
  }
}

variable "cgf_defaultgateway" {
  type        = "map"
  description = ""

  default = {
    "blue"  = "172.16.100.1"
    "green" = "172.16.101.1"
  }
}

variable "cgf_vmsize" {
  type        = "map"
  description = ""

  default = {
    "blue"  = "Standard_DS1_v2"
    "green" = "Standard_DS1_v2"
  }
}

variable "waf_ip_addresses" {
  type        = "map"
  description = ""

  default = {
    "blue"  = ["172.16.100.70"]
    "green" = ["172.16.101.70"]
  }
}

variable "waf_subnetmask" {
  type        = "map"
  description = ""

  default = {
    "blue"  = ["26"]
    "green" = ["26"]
  }
}

variable "waf_defaultgateway" {
  type        = "map"
  description = ""

  default = {
    "blue"  = ["172.16.100.65"]
    "green" = ["172.16.101.65"]
  }
}

variable "waf_vmsize" {
  type        = "map"
  description = ""

  default = {
    "blue"  = "Standard_DS1_v2"
    "green" = "Standard_DS1_v2"
  }
}

variable "web_ipaddress" {
  type        = "map"
  description = ""

  default = {
    "blue"  = "172.16.100.132"
    "green" = "172.16.101.132"
  }
}

variable "sql_ipaddress" {
  type        = "map"
  description = ""

  default = {
    "blue"  = "172.16.100.196"
    "green" = "172.16.101.196"
  }
}

##############################################################################################################

