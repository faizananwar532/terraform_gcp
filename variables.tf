variable "project_id" {
  description = "GCP Project ID"
  type        = string
  sensitive = true
}

variable "credentials" {
  description = "Path to the GCP credentials JSON file"
  type        = string
  sensitive = true
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for zonal resources"
  type        = string
  default     = "us-central1-a"
}

variable "devops-bucket" {
  description = "Name of the static site bucket"
  type        = string
  default     = "devops-static-site-april14"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "april-cluster"
}

variable "zone_name" {
  description = "Zone for GKE cluster"
  type        = string
  default     = "us-central1-a"
}

variable "mach_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}