variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
  default     = "thales-sovereign-cloud"
}

variable "region" {
  description = "The GCP region to deploy resources in"
  type        = string
  default     = "europe-west9"
}

variable "gke_num_nodes" {
  description = "Number of nodes in the primary GKE node pool"
  type        = number
  default     = 3
}
