# Region
variable "region" {
  default = "us-east-1"
}

# Tags
variable "availability_zone" {
  default =  "us-east-1a"
}

variable "env_tag" {
  description = "Environment tag"
  default = "dev"
}