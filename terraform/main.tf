resource "ovh_cloud_project_network_private" "private_network"{
  name="resauPrive${var.instanceName}"
  service_name= var.service_name
  regions= var.region
  vlan_id= var.vlanId
}
resource "ovh_cloud_project_network_private_subnet" "subnetwork_GRA"{
  network_id= ovh_cloud_project_network_private.private_network.id
  service_name= var.service_name
  network=var.vlan_dhcp_reseau
  region= element(var.region,0)
  start= var.vlan_dhcp_start
  end= var.vlan_dhcp_finish
  provider=ovh
  no_gateway= true
}
resource "ovh_cloud_project_network_private_subnet" "subnetwork_SBG"{
  network_id = ovh_cloud_project_network_private.private_network.id
  service_name = var.service_name
  region= element(var.region,1)
  network= var.vlan_dhcp_reseau
  start=var.vlan_dhcp_start
  end=var.vlan_dhcp_finish 
  provider=ovh.ovh
  no_gateway=true
}



resource "openstack_compute_keypair_v2" "test_keypair"{
  count= length(var.region)
  provider=openstack.ovh
  name="sshkey_${var.instanceName}_${count.index%2==0 ? "GRA" :"SGB" }"
  public_key= file("~/.ssh/id_rsa.pub")
  region= element(var.region, count.index)
}

resource  "openstack_compute_instance_v2" "front" {
  name="front_${var.instanceName}"
  provider =openstack.ovh
  flavor_name= var.flavorName
  image_name= var.imageName
  region = element(var.region,0)
  
  key_pair= openstack_compute_keypair_v2.test_keypair[0].name
  
  network {
    name= "Ext-Net"
  }
  network{
    name= ovh_cloud_project_network_private.private_network.name
    fixed_ip_v4 ="192.168.${var.vlanId}.254"
    }
  depends_on = [ovh_cloud_project_network_private_subnet.subnetwork_GRA]
  }
  
  resource "openstack_compute_instance_v2" "backend_GRA"{
    count= var.backNumberOfInstances
    name= "backend_$(var.instanceName}_GRA_${count.index+2}"
    provider= openstack.ovh
    flavor_name=var.flavorName
    image_name= var.imageName
    region= element(var.region,0)
    
    network{
      name= "Ext-Net"
      }
    network{
      name=ovh_cloud_project_network_private.private_network.name
      fixed_ip_v4="192.168.${var.vlanId}.${count.index+1}"
      }
     depends_on=[ovh_cloud_project_network_private_subnet.subnetwork_GRA]
     }
  resource "openstack_compute_instance_v2" "back_SBG"{
    count= var.backNumberOfInstances
    name = "backend_${var.instanceName}_sbg_${count.index+1}" 
    provider= openstack.ovh
    image_name= var.imageName
    flavor_name=var.flavorName
    region = element(var.region,1)
    
    key_pair= openstack_compute_keypair_v2.test_keypair[1].name
    
    network{
      name = ovh_cloud_project_network_private.private_network.name
      fixed_ip_v4="192.168.${var.vlanId}.${count.index+101}"
      }
    depends_on = [ovh_cloud_project_network_private_subnet.subnetwork_SBG]
    }
    
    
    resource "local_file" "inventory"{
      filename= "../ansible/inventory.yml"
      content= templatefile("templates/inventory.yml",
        {
          front= openstack_compute_instance_v2.front.access_ip_v4,
          backends_SBG= [for i , j in openstack_compute_instance_v2.backend_sbg: j.access_ipv4],
          backend_GRA = [for i , j in openstack_compute_instance_v2.backend_gra: j.access_ip_v4],
        }
      )
      }
      
