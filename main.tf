
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


resource "aws_s3_object" "data_object" {
  bucket = var.bucket_name
  key    = "data-upload"
  source = var.data_path
  # content = data.http.source_data.request_body
  # content_type = "application/json"

  depends_on = [module.s3_bucket, data.http.source_data]
  etag = filemd5(var.data_path)
}
#source: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object.html 

resource "aws_s3_object" "script_object" {
  bucket       = var.bucket_name
  key          = "script-upload"
  source      = var.script_path
  
  depends_on = [module.s3_bucket] #source: https://spacelift.io/blog/terraform-depends-on 
  etag       = filemd5(var.script_path)
}

#data extraction
data "http" "source_data" {
  url = var.data_location

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

resource "random_uuid" "condition_check" {
  lifecycle {
    precondition {
      condition     = contains([200], data.http.source_data.status_code)
      error_message = "Status code invalid"
    }
  }
}
#source: https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http


output "test_data" {
  value = data.http.source_data.request_body
}