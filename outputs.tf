output "vpc_name" {
  description = "VPC name"
  value       = google_compute_network.cockroach_vpc.name
}

output "subnet_1_name" {
  value = google_compute_subnetwork.subnet_1.name
}

output "subnet_2_name" {
  value = google_compute_subnetwork.subnet_2.name
}

output "subnet_3_name" {
  value = google_compute_subnetwork.subnet_3.name
}

output "cockroach_1_internal_ip" {
  value = google_compute_instance.cockroach_1.network_interface[0].network_ip
}

output "cockroach_1_external_ip" {
  value = google_compute_instance.cockroach_1.network_interface[0].access_config[0].nat_ip
}

output "cockroach_2_internal_ip" {
  value = google_compute_instance.cockroach_2.network_interface[0].network_ip
}

output "cockroach_2_external_ip" {
  value = google_compute_instance.cockroach_2.network_interface[0].access_config[0].nat_ip
}

output "cockroach_3_internal_ip" {
  value = google_compute_instance.cockroach_3.network_interface[0].network_ip
}

output "cockroach_3_external_ip" {
  value = google_compute_instance.cockroach_3.network_interface[0].access_config[0].nat_ip
}
