terraform {
  backend "s3" {
    bucket = "assaabloy-terraform-state"
    key    = "global/terraform.tfstate"
    region = "eu-north-1"
  }
}
