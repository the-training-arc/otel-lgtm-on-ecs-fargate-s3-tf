variable "environment" {
  type    = string
  default = "dev"
}

variable "service_name" {
  description = "Service Name"
  type        = string
  default     = "elemnta-lgtm"
}

variable "region" {
  description = "Region"
  type        = string
  default     = "ap-southeast-1"
}
