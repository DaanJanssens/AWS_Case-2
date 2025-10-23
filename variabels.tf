variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "zone1" {
  description = "Availability zone voor subnet"
  type        = string
  default     = "eu-central-1a"
}

variable "zone2" {
  description = "Availability zone voor subnet"
  type        = string
  default     = "eu-central-1b"
}

variable "vpc_cidr" {
  description = "CIDR block voor de VPC"
  type        = string
  default     = "192.168.0.0/16"
}
