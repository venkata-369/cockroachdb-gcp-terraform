variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "crdb-learning"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-south1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "asia-south1-a"
}

variable "machine_type" {
  description = "GCP VM machine type"
  type        = string
  default     = "e2-standard-2"
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "cockroach-vpc"
}

variable "subnet_1_cidr" {
  description = "CIDR for subnet 1"
  type        = string
  default     = "10.10.1.0/24"
}

variable "subnet_2_cidr" {
  description = "CIDR for subnet 2"
  type        = string
  default     = "10.10.2.0/24"
}

variable "subnet_3_cidr" {
  description = "CIDR for subnet 3"
  type        = string
  default     = "10.10.3.0/24"
}

variable "ssh_source_ranges" {
  description = "CIDR ranges allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
