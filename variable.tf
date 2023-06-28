# variable "bucket_name" {
#   type        = string
#   description = "This variable is to define the bucket name"
# }

variable "tags" {
  type = map(string)
  default = {
    Owner = "burhan"
    Env   = "non-prod"
  }
}

variable "instance_type" {
  type        = string
  description = "This variable is to the Instance type of EC2"
}

variable "keypair" {
  type = string
}