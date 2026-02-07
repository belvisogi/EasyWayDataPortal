variable "gitlab_url" {
  type        = string
  description = "Base URL of the GitLab instance (e.g. http://80.225.86.168:8929/)"
}

variable "client_name" {
  type        = string
  description = "Name of the client (used for Root Group and username suffix)"
}

variable "initial_bot_password" {
  type        = string
  description = "Initial password for created bot users (Must be changed after init)"
  sensitive   = true
}

variable "enable_agents" {
  type        = bool
  description = "Whether to provision the standard Agentic Council users"
  default     = true
}
