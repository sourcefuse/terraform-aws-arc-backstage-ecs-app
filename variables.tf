################################################################################
## shared
################################################################################
variable "vpc_id" {
  description = "Id of the VPC where the resources will live"
  type        = string
}

variable "tags" {
  description = "Tags to assign the resources."
  type        = map(string)
  default     = {}
}

variable "environment" {
  type        = string
  description = "ID element. Usually used for region e.g. 'uw2', 'us-west-2', OR role 'prod', 'staging', 'dev', 'UAT'"
}
################################################################################
## Backstage service variables
################################################################################

variable "health_check_path_pattern" {
  type        = string
  description = "Path pattern to match against the request URL."
  default     = "/"
}

variable "container_image" {
  type        = string
  description = "url for image being used to setup backstage"
  default     = "spotify/backstage-cookiecutter"
}

variable "app_port_number" {
  description = "Port number for the container to run under"
  type        = number
  default     = 7007
}

variable "app_host_name" {
  description = "Host name to expose via Route53"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster."
  type        = string
}

variable "cluster_id" {
  description = "ID of the ECS cluster."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs to run health check task in"
  type        = list(string)
}

variable "egress_cidr_block" {
  default     = "0.0.0.0/0"
  type        = string
  description = "ECS Tasks egress CIDR block"
}

variable "task_definition_cpu" {
  type        = number
  description = "Number of cpu units used by the task. If the requires_compatibilities is FARGATE this field is required."
  default     = 1024
}

variable "task_definition_memory" {
  type        = number
  description = "Amount (in MiB) of memory used by the task. If the requires_compatibilities is FARGATE this field is required."
  default     = 2048
}

variable "execution_policy_attachment_arns" {
  type        = list(string)
  description = "The ARNs of the policies you want to apply"
  default = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

variable "secret_name" {
  type        = string
  description = "Name of the secret in AWS Secrets Manager that contains Backstage secrets, such as POSTGRES_USER and POSTGRES_PASSWORD"
  default     = "arc/poc/backstage"
}

variable "private_key_secret_name" {
  type        = string
  description = "Name of the secret in AWS Secrets Manager that contains Backstage private key for GitHub authentication. The secret should be stored as plain text in ASM."
  default     = "arc/poc/backstage-private-key"
}

variable "route_53_records" {
  type        = list(string)
  description = "List of A record domains to create for the health check service"
}

variable "route_53_record_type" {
  default     = "A"
  type        = string
  description = "Health check Route53 record type"
}

variable "launch_type" {
  default     = "FARGATE"
  type        = string
  description = "Launch type for the health check service."
}

variable "desired_count" {
  default     = 3
  type        = number
  description = "Number of ECS tasks to run for the service."
}

variable "min_count" {
  default     = 1
  type        = number
  description = "Minimum number of ECS tasks to run for the service."
}

variable "max_count" {
  default     = 6
  type        = number
  description = "Maximum number of ECS tasks to run for the service."
}

variable "alb_dns_name" {
  type        = string
  description = "ALB DNS name to create A record for health check service"
}

variable "alb_zone_id" {
  type        = string
  description = "ALB Route53 zone ID to create A record for health check service"
}

variable "route_53_zone_name" {
  type        = string
  description = "Route53 zone name used for looking up and creating an `A` record for the health check service"
}

variable "backstage_environment" {
  default     = "production"
  type        = string
  description = "Backstage environment"
}
################################################################################
## alb
################################################################################
variable "lb_security_group_ids" {
  type        = list(string)
  description = "LB Security Group IDs for ingress access to the health check task definition."
}

variable "lb_listener_arn" {
  type        = string
  description = "ARN of the load balancer listener."
}

################################################################################
## route 53
################################################################################
variable "route_53_private_zone" {
  type        = bool
  description = "Used with `name` field to get a private Hosted Zone"
  default     = false
}
