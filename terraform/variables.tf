variable "region" {
  description = "The AWS region to create resources in."
  type        = string
  default     = "eu-west-2"
}

variable "project" {
  default = "project-bedrock"
}