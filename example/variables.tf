################################################################
## shared
################################################################
variable "namespace" {
  description = "Namespace for the resources."
  default     = "refarchdevops"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "ID element. Usually used for region e.g. 'uw2', 'us-west-2', OR role 'prod', 'staging', 'dev', 'UAT'"
}

variable "profile" {
  type        = string
  default     = "default"
  description = "Name of the AWS profile to use"
}

variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

################################################################################
## acm
################################################################################
variable "acm_domain_name" {
  description = "Domain name the ACM Certificate belongs to"
  type        = string
  default     = "*.sfrefarch.com"
}

################################################################################
## task execution
################################################################################
variable "execution_policy_attachment_arns" {
  type        = list(string)
  description = "The ARNs of the policies you want to apply"
  default = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

variable "app_host_name" {
  description = "Host name to expose via Route53"
  type        = string
  default     = "dx.sfrefarch.com"
}

variable "container_image" {
  type        = string
  description = "url for image being used to setup backstage"
  default     = "spotify/backstage-cookiecutter"
}

variable "secret_name" {
  type        = string
  description = "Name of the secret in AWS Secrets Manager that contains Backstage secrets, such as POSTGRES_USER and POSTGRES_PASSWORD"
  default     = "dev-backstage"
}

variable "route_53_zone_name" {
  type        = string
  description = "Route53 zone name used for looking up and creating an `A` record for the health check service"
  default     = "sfrefarch.com"
}

variable "desired_count" {
  default     = 1
  type        = number
  description = "Number of ECS tasks to run for the health check."
}
