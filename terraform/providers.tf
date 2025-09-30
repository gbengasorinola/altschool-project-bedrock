terraform {
  backend "s3" {
    bucket         = "altschool-project-bedrock-terraform"
    key            = "global/s3/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "altschool-project-bedrock-terraform-locks"
    encrypt        = true
    
  }
}

provider "aws" {
  region = "eu-west-2"
}

