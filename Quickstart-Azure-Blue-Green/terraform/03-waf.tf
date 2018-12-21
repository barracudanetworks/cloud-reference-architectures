##############################################################################################################
#  _                         
# |_) _  __ __ _  _     _| _ 
# |_)(_| |  | (_|(_ |_|(_|(_|
#                                                    
# Terraform configuration for Blue/Green deployment: Barracuda Web Application Firewall
#
##############################################################################################################

resource "azurerm_resource_group" "resourcegroupwaf" {
  name     = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-RG-WAF"
  location = "${var.LOCATION}"
}

resource "azurerm_availability_set" "wafavset" {
  name                = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-WAF-AVSET"
  location            = "${var.LOCATION}"
  managed             = true
  resource_group_name = "${azurerm_resource_group.resourcegroupwaf.name}"
  platform_fault_domain_count   = 2
  platform_update_domain_count  = 5
}

resource "azurerm_public_ip" "waflbpip" {
  name                         = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-LB-WAF-PIP"
  location                     = "${var.LOCATION}"
  resource_group_name          = "${azurerm_resource_group.resourcegroupwaf.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${format("%s-%s-waf-pip", lower(var.PREFIX), lower(var.DEPLOYMENTCOLOR))}"
}

resource "azurerm_lb" "waflb" {
  name                = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-LB-WAF"
  location            = "${var.LOCATION}"
  resource_group_name = "${azurerm_resource_group.resourcegroupwaf.name}"

  frontend_ip_configuration {
    name                 = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-LB-WAF-PIP"
    public_ip_address_id = "${azurerm_public_ip.waflbpip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "waflbbackend" {
  resource_group_name = "${azurerm_resource_group.resourcegroupwaf.name}"
  loadbalancer_id     = "${azurerm_lb.waflb.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "waflbprobe" {
  resource_group_name = "${azurerm_resource_group.resourcegroupwaf.name}"
  loadbalancer_id     = "${azurerm_lb.waflb.id}"
  name                = "HTTPS-PROBE"
  port                = 443
}

resource "azurerm_lb_rule" "waflbrulehttp" {
  resource_group_name            = "${azurerm_resource_group.resourcegroupwaf.name}"
  loadbalancer_id                = "${azurerm_lb.waflb.id}"
  name                           = "HTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-LB-WAF-PIP"
  probe_id                       = "${azurerm_lb_probe.waflbprobe.id}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.waflbbackend.id}"
}

resource "azurerm_lb_rule" "waflbrulehttps" {
  resource_group_name            = "${azurerm_resource_group.resourcegroupwaf.name}"
  loadbalancer_id                = "${azurerm_lb.waflb.id}"
  name                           = "HTTPS"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-LB-WAF-PIP"
  probe_id                       = "${azurerm_lb_probe.waflbprobe.id}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.waflbbackend.id}"
  depends_on                     = ["azurerm_lb_probe.waflbprobe"]
}

resource "azurerm_lb_nat_rule" "waflbnatrulehttp" {
  name                           = "MGMT-HTTP-WAF-${count.index}"
  count                          = "${length(var.waf_ip_addresses)}"
  loadbalancer_id                = "${azurerm_lb.waflb.id}"
  resource_group_name            = "${azurerm_resource_group.resourcegroupwaf.name}"
  protocol                       = "tcp"
  frontend_port                  = "${count.index + 8000}"
  backend_port                   = 8000
  frontend_ip_configuration_name = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-LB-WAF-PIP"
}

resource "azurerm_lb_nat_rule" "waflbnatrulehttps" {
  name                           = "MGMT-HTTPS-WAF-${count.index}"
  count                          = "${length(var.waf_ip_addresses)}"
  loadbalancer_id                = "${azurerm_lb.waflb.id}"
  resource_group_name            = "${azurerm_resource_group.resourcegroupwaf.name}"
  protocol                       = "tcp"
  frontend_port                  = "${count.index + 8443}"
  backend_port                   = 8443
  frontend_ip_configuration_name = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-LB-WAF-PIP"
}

resource "azurerm_network_interface" "wafifc" {
  name                = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-VM-WAF-IFC-${count.index}"
  count               = "${length(var.waf_ip_addresses[var.DEPLOYMENTCOLOR])}"
  location            = "${azurerm_resource_group.resourcegroupwaf.location}"
  resource_group_name = "${azurerm_resource_group.resourcegroupwaf.name}"

  ip_configuration {
    name                                    = "interface1"
    subnet_id                               = "${azurerm_subnet.subnet2.id}"
    private_ip_address_allocation           = "static"
    private_ip_address                      = "${element(var.waf_ip_addresses[var.DEPLOYMENTCOLOR], count.index)}"
    load_balancer_inbound_nat_rules_ids     = ["${element(azurerm_lb_nat_rule.waflbnatrulehttp.*.id, count.index)}", "${element(azurerm_lb_nat_rule.waflbnatrulehttps.*.id, count.index)}"]
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "wafifclbb" {
  network_interface_id    = "${azurerm_network_interface.wafifc.id}"
  ip_configuration_name   = "interface1"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.waflbbackend.id}"
}

resource "azurerm_virtual_machine" "wafvm" {
  name                  = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-VM-WAF-${count.index}"
  count                 = "${length(var.waf_ip_addresses[var.DEPLOYMENTCOLOR])}"
  location              = "${azurerm_resource_group.resourcegroupwaf.location}"
  resource_group_name   = "${azurerm_resource_group.resourcegroupwaf.name}"
  network_interface_ids = ["${element(azurerm_network_interface.wafifc.*.id, count.index)}"]
  vm_size               = "${var.waf_vmsize[var.DEPLOYMENTCOLOR]}"
  availability_set_id   = "${azurerm_availability_set.wafavset.id}"

  identity {
    type      = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "barracudanetworks"
    offer     = "waf"
    sku       = "${var.WAFIMAGESKU}"
    version   = "latest"
  }

  plan {
    publisher = "barracudanetworks"
    product   = "waf"
    name      = "${var.WAFIMAGESKU}"
  }

  storage_os_disk {
    name              = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-VM-WAF-OSDISK-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-VM-WAF-${count.index}"
    admin_username = "notused"
    admin_password = "${var.PASSWORD}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "quickstart"
    vendor = "Barracuda Networks"
  }
}

data "template_file" "waf_ansible" {
  count    = "${length(var.waf_ip_addresses[var.DEPLOYMENTCOLOR])}"
  template = "${file("${path.module}/ansible_host.tpl")}"

  vars {
    name      = "${var.PREFIX}-${var.DEPLOYMENTCOLOR}-VM-WAF-${count.index}"
    arguments = "ansible_host=${data.azurerm_public_ip.waflbpip.ip_address} ansible_port=${count.index + 8000} ansible_connection=local gather_facts=no"
  }

  depends_on = ["azurerm_virtual_machine.wafvm"]
}

output "waf_private_ip_address" {
  value = "${azurerm_network_interface.wafifc.*.private_ip_address}"
}

data "azurerm_public_ip" "waflbpip" {
  name                = "${azurerm_public_ip.waflbpip.name}"
  resource_group_name = "${azurerm_resource_group.resourcegroupwaf.name}"
}

output "waf_lb_domain_name_label" {
  value = "${data.azurerm_public_ip.waflbpip.domain_name_label}"
}

output "waf_lb_public_ip_address" {
  value = "${data.azurerm_public_ip.waflbpip.ip_address}"
}
