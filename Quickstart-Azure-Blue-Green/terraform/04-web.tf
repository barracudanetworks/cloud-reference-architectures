##############################################################################################################
#  _                         
# |_) _  __ __ _  _     _| _ 
# |_)(_| |  | (_|(_ |_|(_|(_|
#                                                    
# Terraform configuration for Blue/Green deployment: Web Server
#
##############################################################################################################

resource "azurerm_resource_group" "resourcegroupweb" {
  name     = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-RG-WEB"
  location = "${var.LOCATION}"
}

resource "azurerm_network_interface" "webifc" {
  name                 = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-VM-WEB-IFC"
  location             = "${azurerm_resource_group.resourcegroupweb.location}"
  resource_group_name  = "${azurerm_resource_group.resourcegroupweb.name}"
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "interface1"
    subnet_id                     = "${azurerm_subnet.subnet3.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${var.web_ipaddress[var.DEPLOYMENTCOLOR]}"
  }
}

resource "azurerm_virtual_machine" "webvm" {
  name                  = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-VM-WEB"
  location              = "${azurerm_resource_group.resourcegroupweb.location}"
  resource_group_name   = "${azurerm_resource_group.resourcegroupweb.name}"
  network_interface_ids = ["${azurerm_network_interface.webifc.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-VM-WEB-OSDISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-VM-WEB"
    admin_username = "azureuser"
    admin_password = "${var.PASSWORD}"
  }

  os_profile_linux_config {
    disable_password_authentication = false

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = "${var.SSH_KEY_DATA}"
    }
  }

  tags {
    environment = "quickstart"
    vendor = "Barracuda Networks"
  }
}

data "template_file" "web_ansible" {
  count    = 1
  template = "${file("${path.module}/ansible_host_lnx.tpl")}"

  vars {
    name      = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-VM-WEB"
    arguments = "ansible_host=${data.azurerm_public_ip.cgfpipa.ip_address} ansible_port=8444 gather_facts=no internal_host=${azurerm_network_interface.sqlifc.private_ip_address}"
  }

  depends_on = ["azurerm_virtual_machine.webvm"]
}

output "web_private_ip_address" {
  value = "${azurerm_network_interface.webifc.private_ip_address}"
}
