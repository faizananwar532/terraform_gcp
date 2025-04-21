# Storage buckets
resource "google_storage_bucket" "backend_bucket" {
  name          = "apriltfbackend"
  location      = "US"
  force_destroy = true
  public_access_prevention = "enforced"
}

resource "google_storage_bucket" "static-site" {
  name          = var.devops-bucket
  location      = var.region
  force_destroy = true
  storage_class = "REGIONAL"
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
}

resource "google_storage_default_object_access_control" "public_rule" {
  bucket = google_storage_bucket.static-site.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_storage_bucket_object" "index" {
  name   = "index.html"
  source = "./index.html"
  bucket = google_storage_bucket.static-site.name
}

# Networking
resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = "april-vpc-network"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges" {
  name          = "april-subnetwork"
  ip_cidr_range = "10.2.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  secondary_ip_range {
    range_name    = "tf-test-secondary-range-update1"
    ip_cidr_range = "192.168.10.0/24"
  }
}

# Compute instances
resource "google_compute_instance" "vm" {
  count        = 2  # This will create 2 identical VMs
  name         = "vm-${count.index + 1}"  # Names will be vm-1 and vm-2
  machine_type = "e2-micro"  # Minimal machine type (free tier eligible)
  zone         = var.zone  # Change to your preferred zone
  allow_stopping_for_update = true
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"  # Lightweight OS
    }
  }
  
  network_interface {
    network = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.network-with-private-secondary-ip-ranges.self_link
    access_config {}  # This gives each VM an ephemeral public IP
  }
  
  metadata_startup_script = "echo 'Hello from VM ${count.index + 1}' > /test.txt"
}

# Artifact Registry
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "april14"
  format        = "DOCKER"
}

# Build and push Docker image
resource "null_resource" "build_and_push_image" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud builds submit --tag ${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}/hello-cloud-run ./app
    EOT
  }
  
  depends_on = [google_artifact_registry_repository.repo]
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone_name
  remove_default_node_pool = false
  deletion_protection      = false
  initial_node_count       = 2
  
  node_config {
    preemptible  = true
    machine_type = var.mach_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  
  lifecycle {
    ignore_changes = [enable_l4_ilb_subsetting, master_authorized_networks_config]
  }
  
  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = false
    master_ipv4_cidr_block = "172.16.0.0/28"
  }
  
  ip_allocation_policy {
    services_ipv4_cidr_block = "10.60.0.0/20"
    cluster_ipv4_cidr_block = "10.56.0.0/14"
  }
  
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = "14.15.16.17/32"
      display_name = "office-ip1"
    }
  }
}

# Cloud Run Service
resource "google_cloud_run_service" "default" {
  name     = "hello-cloud-run"
  location = var.region

  template {
    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}/hello-cloud-run"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [null_resource.build_and_push_image]
}

resource "google_cloud_run_service_iam_member" "invoker" {
  location = google_cloud_run_service.default.location
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"

  depends_on = [google_cloud_run_service.default]
}

# Outputs
output "cloud_run_url" {
  value = google_cloud_run_service.default.status[0].url
}