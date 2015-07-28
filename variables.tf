### MANDATORY ###

variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
  default = "infrastructure"
}

### MANDATORY ###
variable "key_path" {
  description = "Path to the private portion of the SSH key specified."
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default = "ap-southeast-2"
}

variable "subnet_id"{
  description = "Default subnet to launch instances into."
}

variable "amazon_nat_ami" {
  default = {
    eu-central-1 = "ami-46073a5b"
    ap-southeast-1 = "ami-b49dace6"
    ap-southeast-2 = "ami-e7ee9edd"
    us-west-1 = "ami-7da94839"
  }
}
