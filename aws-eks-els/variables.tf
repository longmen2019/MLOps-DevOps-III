############################################
# VPC Module Variables
############################################
variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "access_ip" {
  description = "CIDR allowed to access public resources (e.g., SSH, ALB)."
  default     = "0.0.0.0/0"
}

variable "public_sn_count" {
  description = "Number of public subnets to create."
  default     = 2
}

variable "public_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(any)
  default     = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "instance_tenancy" {
  description = "EC2 instance tenancy option for the VPC (default or dedicated)."
  default     = "default"
}

variable "tags" {
  description = "Tags to apply to VPC resources."
  default = {
    Environment = "dev"
    Project     = "eks-demo"
    Owner       = "cloudquicklabs"
  }
}
############################################
# EKS Module Variables
############################################

variable "endpoint_public_access" {
  description = "Enable public access to EKS API endpoint"
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Enable private access to EKS API endpoint"
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to access the public EKS endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}