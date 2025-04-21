terraform {
  backend "gcs" { 
    # these will be passed with backend.tfvars file
    # bucket  = "bucket name"
    # prefix  = "terraform/state"
    # credentials = "./service account key path"
  }
}
