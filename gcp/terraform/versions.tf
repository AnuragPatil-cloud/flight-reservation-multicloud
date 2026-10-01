terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.30" # any 7.x from 7.30; provider 8.0 has breaking changes
    }
  }
}
