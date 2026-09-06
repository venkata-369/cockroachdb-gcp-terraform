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
  description = "CIDRs allowed to SSH (port 22). REPLACE with your own IP for a secure deployment."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "db_console_source_ranges" {
  description = "CIDRs allowed to reach the DB Console (port 8080). REPLACE with your own IP."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "crdb_version" {
  description = "CockroachDB version installed on the VMs (no leading 'v'). Verify at https://www.cockroachlabs.com/docs/releases before changing."
  type        = string
  default     = "24.3.33"
}
