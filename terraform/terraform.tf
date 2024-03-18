terraform {
  required_version = "~> 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
  cloud {
    organization = "abcaballero"
    workspaces {
      name = "word-trend-language-learner"
    }
  }
}