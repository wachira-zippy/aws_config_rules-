data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

variable "is_enabled" {}

variable "config_name" {}

variable "config_logs_bucket" {}

variable "config_logs_prefix" {}

variable "config_delivery_frequency" {}

variable "include_global_resource_types" {}