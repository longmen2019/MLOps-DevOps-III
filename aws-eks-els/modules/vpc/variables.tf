
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "access_ip" {
  description = "CIDR allowed to access public resources"
  type        = string
}

variable "public_sn_count" {
  description = "Number of public subnets to create"
  type        = number
}

variable "public_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "instance_tenancy" {
  description = "EC2 instance tenancy option for the VPC"
  type        = string
  default     = "default"
}

variable "tags" {
  description = "Tags to apply to VPC resources"
  type        = map(string)
}

variable "map_public_ip_on_launch" {
  description = "Assign public IPs to instances launched in public subnets"
  type        = bool
  default     = true
}

variable "rt_route_cidr_block" {
  description = "CIDR block for the default route in public route tables"
  type        = string
  default     = "0.0.0.0/0"
}
