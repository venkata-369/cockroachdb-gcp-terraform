output "vpc_name" {
  description = "VPC name"
  value       = google_compute_network.cockroach_vpc.name
}

output "subnet_names" {
  value = [
    google_compute_subnetwork.subnet_1.name,
    google_compute_subnetwork.subnet_2.name,
    google_compute_subnetwork.subnet_3.name,
  ]
}

output "node_internal_ips" {
  description = "Internal IPs (use these in --join and --advertise-addr)"
  value       = { for k, m in module.cockroach_node : k => m.internal_ip }
}

output "node_external_ips" {
  description = "External IPs (use these for SSH, cert upload, and reaching the DB Console)"
  value       = { for k, m in module.cockroach_node : k => m.external_ip }
}

output "join_string" {
  description = "Ready-to-paste --join value for cockroach start"
  value       = join(",", [for m in module.cockroach_node : m.internal_ip])
}
