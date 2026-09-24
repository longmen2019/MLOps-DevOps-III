variable "name" {
  description = "Name used for the instance, security group, and tags"
  type        = string
  default = "mcp-aws"
}

variable "ami" {
  description = "AMI ID to use. If null, ami_ssm_parameter is used instead"
  type        = string
  default     = null
}

variable "ami_ssm_parameter" {
  description = "SSM parameter name to look up the AMI ID (used when ami is null)"
  type        = string
  default     = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "m7i-flex.large"
}

variable "vpc_cidr" {
  description = "CIDR block for the new VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the new public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
  default = "us-east-1a"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP with the instance"
  type        = bool
  default     = true
}

variable "user_data" {
  description = "User data script to run on instance boot"
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}

variable "create_security_group" {
  description = "Whether to create a security group for the instance"
  type        = bool
  default     = true
}

variable "vpc_security_group_ids" {
  description = "Existing security group IDs to attach (used if create_security_group is false)"
  type        = list(string)
  default     = []
}

variable "ingress_rules" {
  description = "List of ingress rules for the security group, e.g. SSH (22) and your MCP server port"
  type = list(object({
    description = optional(string)
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "create_eip" {
  description = "Whether to allocate and attach an Elastic IP"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
