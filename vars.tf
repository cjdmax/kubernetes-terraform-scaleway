variable "organization_key" {
  description = "Scaleway access_key"
}

variable "secret_key" {
  description = "Scaleway secret_key"
}

variable "region" {
  description = "Scaleway region: Paris (PAR1) or Amsterdam (AMS1)"
}

variable "user" {
  description = "Username to connect the server"
  default = "root"
}

variable "dynamic_ip" {
  description = "Enable or disable server dynamic public ip"
  default = "true"
}

variable "scaleway_image_arch" {
  description = "Scaleway Imagehub architecture"
}

variable "scaleway_image_name" {
  description = "Scaleway Imagehub name"
}

variable "scaleway_bootscript" {
  description = "Scaleway Bootscript"
}

variable "scaleway_slave_type" {
  description = "Instance type of Slave"
}

variable "scaleway_master_type" {
  description = "Instance type of Master"
}

variable "kubernetes_cluster_name" {
  description = "Name of your cluster. Alpha-numeric and hyphens only, please."
}

variable "kubernetes_slave_count" {
  description = "Number of agents to deploy"
  default = "3"
}

variable "kubernetes_token" {
  description = "Token used to secure cluster boostrap"
}
