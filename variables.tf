variable "key_name" {
  description = "The name of the SSH key pair"
  type        = string
  default     = "tmdb_key"
}

variable "private_key_path" {
  description = "Path to the private key corresponding to the SSH key pair"
  type        = string
  default     = "keys/tmdb_key"
}
