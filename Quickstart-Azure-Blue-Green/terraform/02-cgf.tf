##############################################################################################################
#  _                         
# |_) _  __ __ _  _     _| _ 
# |_)(_| |  | (_|(_ |_|(_|(_|
#                                                    
# Terraform configuration for Blue/Green deployment: Barracuda CloudGen Firewall
#
##############################################################################################################

resource "azurerm_resource_group" "resourcegroupcgf" {
  name     = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-RG-CGF"
  location = "${var.LOCATION}"
}

resource "azurerm_availability_set" "cgfavset" {
  name                          = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-CGF-AVSET"
  location                      = "${var.LOCATION}"
  managed                       = true
  resource_group_name           = "${azurerm_resource_group.resourcegroupcgf.name}"
  platform_fault_domain_count   = 2
  platform_update_domain_count  = 5
}

resource "azurerm_public_ip" "cgflbpip" {
  name                         = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-LB-CGF-PIP"
  location                     = "${var.LOCATION}"
  resource_group_name          = "${azurerm_resource_group.resourcegroupcgf.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${format("%s-%s%s", lower(var.PREFIX), var.DEPLOYMENTCOLOR, "-cgf-pip")}"
}

resource "azurerm_lb" "cgflb" {
  name                = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-LB-CGF"
  location            = "${var.LOCATION}"
  resource_group_name = "${azurerm_resource_group.resourcegroupcgf.name}"

  frontend_ip_configuration {
    name                 = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-LB-CGF-PIP"
    public_ip_address_id = "${azurerm_public_ip.cgflbpip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "cgflbbackend" {
  resource_group_name = "${azurerm_resource_group.resourcegroupcgf.name}"
  loadbalancer_id     = "${azurerm_lb.cgflb.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "cgflbprobe" {
  resource_group_name = "${azurerm_resource_group.resourcegroupcgf.name}"
  loadbalancer_id     = "${azurerm_lb.cgflb.id}"
  name                = "TINA-TCP-PROBE"
  port                = 691
}

resource "azurerm_lb_rule" "cgflbruletinatcp" {
  resource_group_name            = "${azurerm_resource_group.resourcegroupcgf.name}"
  loadbalancer_id                = "${azurerm_lb.cgflb.id}"
  name                           = "TINA-TCP"
  protocol                       = "Tcp"
  frontend_port                  = 691
  backend_port                   = 691
  frontend_ip_configuration_name = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-LB-CGF-PIP"
  probe_id                       = "${azurerm_lb_probe.cgflbprobe.id}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.cgflbbackend.id}"
}

resource "azurerm_lb_rule" "cgflbruletinaudp" {
  resource_group_name            = "${azurerm_resource_group.resourcegroupcgf.name}"
  loadbalancer_id                = "${azurerm_lb.cgflb.id}"
  name                           = "TINA-UDP"
  protocol                       = "Udp"
  frontend_port                  = 691
  backend_port                   = 691
  frontend_ip_configuration_name = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-LB-CGF-PIP"
  probe_id                       = "${azurerm_lb_probe.cgflbprobe.id}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.cgflbbackend.id}"
}

resource "azurerm_lb_rule" "cgflbruleipsecike" {
  resource_group_name            = "${azurerm_resource_group.resourcegroupcgf.name}"
  loadbalancer_id                = "${azurerm_lb.cgflb.id}"
  name                           = "IPSEC-IKE"
  protocol                       = "Udp"
  frontend_port                  = 500
  backend_port                   = 500
  frontend_ip_configuration_name = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-LB-CGF-PIP"
  probe_id                       = "${azurerm_lb_probe.cgflbprobe.id}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.cgflbbackend.id}"
}

resource "azurerm_lb_rule" "cgflbruleipsecnatt" {
  resource_group_name            = "${azurerm_resource_group.resourcegroupcgf.name}"
  loadbalancer_id                = "${azurerm_lb.cgflb.id}"
  name                           = "IPSEC-NATT"
  protocol                       = "Udp"
  frontend_port                  = 4500
  backend_port                   = 4500
  frontend_ip_configuration_name = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-LB-CGF-PIP"
  probe_id                       = "${azurerm_lb_probe.cgflbprobe.id}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.cgflbbackend.id}"
}

resource "azurerm_public_ip" "cgfpipa" {
  name                         = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-VM-CGF-A-PIP"
  location                     = "${var.LOCATION}"
  resource_group_name          = "${azurerm_resource_group.resourcegroupcgf.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "cgfifca" {
  name                 = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-VM-CGF-A-IFC"
  location             = "${azurerm_resource_group.resourcegroupcgf.location}"
  resource_group_name  = "${azurerm_resource_group.resourcegroupcgf.name}"
  enable_ip_forwarding = true

  ip_configuration {
    name                                    = "interface1"
    subnet_id                               = "${azurerm_subnet.subnet1.id}"
    private_ip_address_allocation           = "static"
    private_ip_address                      = "${var.cgf_a_ipaddress[var.DEPLOYMENTCOLOR]}"
    public_ip_address_id                    = "${azurerm_public_ip.cgfpipa.id}"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "cgfifcalbb" {
  network_interface_id    = "${azurerm_network_interface.cgfifca.id}"
  ip_configuration_name   = "interface1"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.cgflbbackend.id}"
}

resource "azurerm_virtual_machine" "cgfvma" {
  name                  = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-VM-CGF-A"
  location              = "${azurerm_resource_group.resourcegroupcgf.location}"
  resource_group_name   = "${azurerm_resource_group.resourcegroupcgf.name}"
  network_interface_ids = ["${azurerm_network_interface.cgfifca.id}"]
  vm_size               = "${var.cgf_vmsize[var.DEPLOYMENTCOLOR]}"
  availability_set_id   = "${azurerm_availability_set.cgfavset.id}"

  identity {
    type      = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "barracudanetworks"
    offer     = "barracuda-ng-firewall"
    sku       = "${var.CGFIMAGESKU}"
    version   = "latest"
  }

  plan {
    publisher = "barracudanetworks"
    product   = "barracuda-ng-firewall"
    name      = "${var.CGFIMAGESKU}"
  }

  storage_os_disk {
    name              = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-VM-CGF-A-OSDISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-VM-CGF-A"
    admin_username = "notused"
    admin_password = "${var.PASSWORD}"
    custom_data    = "${data.template_file.custom_data.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "quickstart"
    vendor = "Barracuda Networks"
  }
}

data "template_file" "custom_data" {
  template = "${file("${path.module}/provisioncgf.sh")}"

  vars {
    cgf_ipaddr = "${var.cgf_a_ipaddress[var.DEPLOYMENTCOLOR]}"
    cgf_mask = "${var.cgf_subnetmask[var.DEPLOYMENTCOLOR]}"
    cgf_gw =  "${var.cgf_defaultgateway[var.DEPLOYMENTCOLOR]}"
  }
}
data "template_file" "cgf_ansible" {
  count    = "1"
  template = "${file("${path.module}/ansible_host.tpl")}"

  vars {
    name      = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-VM-CGF-A"
    arguments = "ansible_host=${data.azurerm_public_ip.cgfpipa.ip_address} ansible_port=8443 ansible_connection=local gather_facts=no"
  }

  depends_on = ["azurerm_virtual_machine.cgfvma"]
}
output "cgf_private_ip_address" {
  value = "${azurerm_network_interface.cgfifca.private_ip_address}"
}

data "azurerm_public_ip" "cgfpipa" {
  name                = "${azurerm_public_ip.cgfpipa.name}"
  resource_group_name = "${azurerm_resource_group.resourcegroupcgf.name}"
}

output "cgf_a_public_ip_address" {
  value = "${data.azurerm_public_ip.cgfpipa.ip_address}"
}

data "azurerm_public_ip" "cgflbpip" {
  name                = "${azurerm_public_ip.cgflbpip.name}"
  resource_group_name = "${azurerm_resource_group.resourcegroupcgf.name}"
}

output "cgf_lb_domain_name_label" {
  value = "${data.azurerm_public_ip.cgflbpip.domain_name_label}"
}

output "cgf_lb_public_ip_address" {
  value = "${data.azurerm_public_ip.cgflbpip.ip_address}"
}
