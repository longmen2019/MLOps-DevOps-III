variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed."
  type        = string
}

variable "aws_public_subnet" {
  description = "List of public subnet IDs for EKS cluster and node groups."
  type        = list(string)
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "eks-demo-cluster"
}

variable "endpoint_private_access" {
  description = "Enable private API endpoint access."
  type        = bool
  default     = false
}

variable "endpoint_public_access" {
  description = "Enable public API endpoint access."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to access the public EKS API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_group_name" {
  description = "Name of the EKS node group."
  type        = string
  default     = "demo-node-group"
}

variable "scaling_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "scaling_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3
}

variable "scaling_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "instance_types" {
  description = "EC2 instance types for the EKS node group."
  type        = list(string)
  default     = ["m7i-flex.large"]

}

variable "key_pair" {
  description = "SSH key pair name for worker nodes."
  type        = string
  default     = "eks-key"
}
