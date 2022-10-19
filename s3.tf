##
# (c) 2021 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#
locals {
  load_balancer_log_bucket    = "${var.default_bucket_prefix}-lb-logs"
  application_versions_bucket = "${var.default_bucket_prefix}-app-versions"
  mod_bucket_version          = "3.4.0"
}

module "versions_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = local.mod_bucket_version

  bucket                  = local.application_versions_bucket
  acl                     = "private"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:alias/aws/s3"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "versions-clean"
      enabled = true

      transition = [
        {
          days          = var.artifact_transition_days
          storage_class = "STANDARD_IA"
        },
        {
          days          = var.artifact_transition_days * 2
          storage_class = "GLACIER"
        }
      ]

      noncurrent_transition = [
        {
          days          = var.artifact_transition_days * 2
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = var.versions_expiration_days
      }

      expiration = {
        days = var.artifact_expiration_days
      }
    }
  ]
}

module "logs_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = local.mod_bucket_version

  bucket                         = local.load_balancer_log_bucket
  acl                            = "log-delivery-write"
  block_public_acls              = true
  block_public_policy            = true
  ignore_public_acls             = true
  restrict_public_buckets        = true
  force_destroy                  = true
  attach_elb_log_delivery_policy = true # Required for ALB logs
  attach_lb_log_delivery_policy  = true # Required for ALB/NLB logs

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        #kms_master_key_id = "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:alias/aws/s3"
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "logs-policy"
      enabled = true

      transition = [
        {
          days          = var.logs_archive_days
          storage_class = "GLACIER"
        }
      ]
      expiration = {
        days = var.logs_expiration_days
      }
    }
  ]
}