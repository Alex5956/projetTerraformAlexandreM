resource "ovh_cloud_projet_reseauPrive" "reseauPrive"{
  name="resauPrive${var.nomInstance}"
  service_name= var.service_name
  regions= var.region
  vlanId= var.vlanId
}
resource "ovh_cloud_project_network_sousreseauPrive" "sousReseau_GRA"{
  networkId= ovh_cloud_projet_reseauPrive.reseauPrive.id
  service_name= var.service_name
  network=var.vlan_dhcp_reseau
  region= element(var.region,0)
  start= var.vlan_dhcp_start
  finish= var.vlan_dhcp_finish
  provider=ovh
  no_gateway= true
}
resource "ovh_cloud_projet_reseauPrive_sousReseau" "sousReseau_SGB"{
  network_id = ovh_cloud_project_reseauPrive.reseauPrive.id
  service_name = var.service_name
  region= element(var.region,1)
  network= var.vlan_dhcp_reseau
  start=var.vlan_dhcp_start
  end=var.vlan_dhchp_finish 
  provider=ovh.ovh
  no_gateway=true
}



resource "openstack_compute_keypair_v2" "test_keypair"{
  count= length(var.region)
  provider=openstack.ovh
  name="sshkey_${var.instance_name}_${count.index%2==0 ? "GRA" :"SGB" }"
  public_key= file("~/.ssh/id_rsa.pub")
  region= elemnt(var.region, count.index)
}

resource  "openstack_compute_instance_v2" "front" {
  name="front_${var.instanceName}"
  provider =openstack.ovh
  flavor_name= var.flavorName
  image_name= var.image_name
  region = element(var.region[0])
  
  key_pair= openstack_compute_keypair_v2.test_keypair[0].name
  
  network {
    name= "Ext-Net"
  }
  network{
    name= ovh_cloud_projet_reseauPrive.reseauPrive.name
    fixed_ip_v4 ="192.168.${var.vlanId}.254"
    }
  depends_on = [ovh_cloud_projet_sousReseauPrive.sousReseau_GRA]
  }
  
  resource "openstack_compute_instance_v2" "back_GRA"{
    count= var.backNumberOfInstances
    name= "backend_$(var.instance_name}_GRA_${count.index+2}"
    provider= openstack.ovh
    flavor_name=var.flavorName
    image_name= var.imageName
    region= element(var.region,0)
    
    network{
      name= "Ext-Net"
      }
    network{
      name=ovh_cloud_projet_reseauPrive.reseauprive.name
      fixed_ip_v4="192.168.${var.vlanId}.${count.index+1}"
      }
     depends_on=[ovh_cloud_projet_sousReseauPrive.sousReseau_GRA]
     }
  resource "openstack_compute_instance_v2" "back_SGB"{
    count= var.BackNumberOfInstances
    name = "backend_${var.instance_name}_sbg_${count.index+1}" 
    provider= openstack.ovh
    image_name= var.image_name
    flavor_name=var.falvorName
    region = elemnt(var.region,1)
    
    key_pair= openstack_compute_keypair_v2.test_keypair[1].name
    
    network{
      name = ovh_cloud_projet_reseauPrive.reseauPrive.name
      fixed_ip_v4="192.168.${var.vlanId}.${count.index+101}"
      }
    depends_on = [ovh_cloud_projet_sousReseauPrive.sousReseau_SGB]
    }
    
    
    resource "local_file" "inventory"{
      filename= "../ansible/inventory.yml"
      content= templatefile("templates/inventory.yml",
        {
          front= openstack_compute_instance_v2.front.access_ip_v4,
          backends_SGB= [for i , j in openstack_compute_instance_v2.back_SGB: j.access_ipv4],
          backend_GRA = [for i , j in openstack_compute_instance_v2.back_GRA: j.access_ip_v4],
        }
      )
      }
      
