
#AWS configuration
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.27.0"
    }
  }
}

provider "aws" {
  region     = "us-east-2"
  access_key = var.aws_access
  secret_key = var.aws_secret
}

#bucket creation
module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = var.bucket_name
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }
}
#source: https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest


#bucket objects
resource "aws_s3_object" "data_object" {
  bucket       = var.bucket_name
  key          = var.pipeline_input
  source       = var.data_path

  depends_on = [module.s3_bucket]
  etag = filemd5(var.data_path)
}

resource "aws_s3_object" "data_output" {
  bucket = var.bucket_name
  key    = var.pipeline_output
  content = "{}"
  content_type = "application/json"

  depends_on = [module.s3_bucket]
} #source: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object.html 

resource "aws_s3_object" "script_object" {
  bucket       = var.bucket_name
  key          = "script-upload.py"
  source       = var.script_path
  
  depends_on   = [module.s3_bucket] #source: https://spacelift.io/blog/terraform-depends-on 
  etag         = filemd5(var.script_path)
}

#glue job
resource "aws_glue_job" "transform_job" {
  name         = "transform_job"
  role_arn     = aws_iam_role.glue_role.arn

  command {
    name            = "pythonshell"
    script_location = "s3://${var.bucket_name}/script-upload.py"
    python_version  = 3
  }
  default_arguments = {
   "--BUCKET_NAME" = var.bucket_name,
   "--input_file"  = var.pipeline_input,
   "--output_file" = var.pipeline_output,
   "--key"         = var.aws_access,
   "--secret_key"  = var.aws_secret,
  }
  depends_on =[aws_s3_object.script_object, aws_s3_object.data_object]
}

resource "aws_iam_role" "glue_role" {
  name = "glue_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    "Version"   : "2012-10-17",
    "Statement" : [
      {
        "Sid"    : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole",
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "Allow-s3"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid"      : "VisualEditor0",
          "Effect"   : "Allow",
          "Action"   : "s3:*",
          "Resource" : "*"
        }
      ]
    })
  }
} #source: https://stackoverflow.com/questions/76184964/how-to-create-an-iam-role-for-aws-glue-using-terraform

#data extraction
# data "http" "source_data" {
#   url = var.data_location

#   # Optional request headers
#   request_headers = {
#     Accept = "application/json"
#   }
# }

# resource "random_uuid" "condition_check" {
#   lifecycle {
#     precondition {
#       condition     = contains([200], data.http.source_data.status_code)
#       error_message = "Status code invalid"
#     }
#   }
# }
#source: https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http



# output "test_data" {
#   value = data.http.source_data.request_body
# }