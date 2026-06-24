
############################
#### Scaleway variables ####

variable "scaleway_region" {
  description = "Scaleway region ID"
  type        = string
}

############################
##### Module variables #####

variable "vpc_name" {
  description = "Name of the VPC to create"
  type        = string
}

