# terraform {
#     required_providers {
#         aws = {
#             source  = "hashicorp/aws"
#             version = "~> 4.16"
#         }
#     }

#     backend "s3" {
#       bucket = "local-state"
#       key    = "messeger/terraform.tfstate"
#       region = var.aws_region
#     }
    
    

#   required_version = ">= 0.12"
# }


# provider "aws" {
#     region = var.aws_region
# }


