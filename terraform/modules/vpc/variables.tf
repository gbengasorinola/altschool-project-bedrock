variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "eu-west-2"
}

variable "project" {
  description = "Project Bedrock"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "A list of availability zones in the region"
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b", "eu-west-2c"] 
}

variable "private_subnets" {
    description = "A list of private subnet CIDR blocks"
    type        = list(string)
}

variable "public_subnets" {
    description = "A list of public subnet CIDR blocks"
    type        = list(string)
}