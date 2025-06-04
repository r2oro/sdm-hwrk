variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "private_user_list" {
  description = "List of users having access to private instances"
  type        = list(string)
  default     = ["a-0d69385f6838c1d0", "a-35ebc92066b1074b"]
}

variable "gateway_user_list" {
  description = "List of users having access to the gateway"
  type        = list(string)
  default     = ["a-0d69385f6838c1d0", "a-35ebc92066b1074b"]
}
