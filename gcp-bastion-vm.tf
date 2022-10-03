provider "google" {
  project = var.projectid
  region = var.region
  zone=var.zone
}


#VPC custom

resource "google_compute_network" "vpc" {
  name = var.vpc_name
  auto_create_subnetworks =  false 
  
}


resource "google_compute_subnetwork" "subnet" {
    name = "subnet"
    network = google_compute_network.vpc.name
    ip_cidr_range = "10.2.0.0/16"
    private_ip_google_access = true
    region = var.region
  
}

#firewall

#allow-ssh-bastion

resource "google_compute_firewall" "rule1" {
 
  name        = "allow-ssh-bastion"
  network     = google_compute_network.vpc.name
  description = "Creates firewall rule targeting tagged instances"

  allow {
    protocol  = "tcp"
    ports     = ["22"]
  }
  source_ranges = [ "35.235.240.0/20" ]
  
  target_tags = ["bastion"]
}

#allow-http-ingress

resource "google_compute_firewall" "rule2" {
 
  name        = "allow-http-ingress"
  network     = google_compute_network.vpc.name
  description = "Creates firewall rule targeting tagged instances"

  allow {
    protocol  = "tcp"
    ports     = ["80"]
  }
  source_ranges = [ "0.0.0.0/0" ]
  
  target_tags = ["flipkart"]
}

#allow-ssh-bastion-flipkart


resource "google_compute_firewall" "rule3" {
 
  name        = "allow-ssh-bastion-flipkart"
  network     = google_compute_network.vpc.name
  description = "Creates firewall rule targeting tagged instances"

  allow {
    protocol  = "tcp"
    ports     = ["22"]
  }
  source_ranges = [ "192.168.10.0/24" ]
  
  target_tags = ["flipkart" , "bastion"]
}


#bastion vm


resource "google_compute_instance" "bastion" {
  name         = "bastion"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  tags = ["bastion"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "SCSI"
  }

  network_interface {
    network = google_compute_network.vpc.name

    
  }

 

  metadata_startup_script = "echo hi > /test.txt"

 
}


#flipkatvm


resource "google_compute_instance" "flipkart" {
  name         = "flipkart"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  tags = ["flipkart"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "SCSI"
  }

  network_interface {
    network = google_compute_network.vpc.name

    access_config {
      // Ephemeral public IP
    }
  }


  metadata_startup_script = "echo hi > /test.txt"

 
}
