# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "alb_ingress_port" {
  description = "Port numbers to allow ingress traffic to ALB"
  type        = number
}
variable "alb_name" {
  description = "The name of the application load balancer"
  type        = string
}
variable "subnet_ids" {
  description = "A list of subnet ids"
  type        = list(string)
}
variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "instance_ids" {
  description = "The instance ids for the target group"
  type        = list(string)
  default     = null
}
