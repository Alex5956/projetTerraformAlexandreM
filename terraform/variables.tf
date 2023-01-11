variable "region" {
  type = list
  default=["GRA11","SGB5"]
}
variable "imageName"{
  type =string
  default="Debian 11"
}
variable "instanceName"{
  type =string
  default= "eductive19"
}
variable "flavorName"{
  type=string
  default="s1-2"
}
variable "backNumberOfInstances"{
  type = number 
  default=1
}

variable "service_name" {
  type    = string
  default ="vRackService"
}

variable  "vlanId" {
  type    = number
  default = 19
}

variable "vlan_dhcp_start" {
  type    = string
  default = "192.168.19.1"
}


variable "vlan_dhcp_finish" {
  type    = string
  default = "192.168.19.200"
}

variable "vlan_dhcp_reseau" {
  type    = string
  default = "192.168.19.0/24"
}
