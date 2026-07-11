mock_provider "aws" {}

variables {
  bucket_name         = "terrasov-test-bucket"
  kms_key_arn         = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
  data_classification = "confidential"
}

run "hardened_defaults" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning must always be enabled."
  }

  assert {
    condition = (
      aws_s3_bucket_public_access_block.this.block_public_acls &&
      aws_s3_bucket_public_access_block.this.block_public_policy &&
      aws_s3_bucket_public_access_block.this.ignore_public_acls &&
      aws_s3_bucket_public_access_block.this.restrict_public_buckets
    )
    error_message = "All four Block Public Access flags must be true."
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default).sse_algorithm == "aws:kms"
    error_message = "Default encryption must be aws:kms with a CMK."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["data_residency"] == "eu"
    error_message = "data_residency tag must be pinned to eu."
  }

  assert {
    condition     = aws_s3_bucket.this.tags["data_classification"] == "confidential"
    error_message = "data_classification tag must reflect the declared classification."
  }

  assert {
    condition     = length(aws_s3_bucket_logging.this) == 0
    error_message = "Access logging resource must not be created when access_log_bucket is null."
  }
}

run "classification_tag_cannot_be_overridden" {
  command = plan

  variables {
    tags = {
      data_classification = "public"
      data_residency      = "us"
    }
  }

  assert {
    condition     = aws_s3_bucket.this.tags["data_classification"] == "confidential" && aws_s3_bucket.this.tags["data_residency"] == "eu"
    error_message = "Module-enforced labels must win over user-supplied tags."
  }
}

run "access_logging_enabled_when_target_given" {
  command = plan

  variables {
    access_log_bucket = "terrasov-test-logs"
  }

  assert {
    condition     = length(aws_s3_bucket_logging.this) == 1 && aws_s3_bucket_logging.this[0].target_bucket == "terrasov-test-logs"
    error_message = "Access logging must be configured when a target bucket is provided."
  }
}

run "rejects_invalid_classification" {
  command = plan

  variables {
    data_classification = "secret"
  }

  expect_failures = [var.data_classification]
}

run "rejects_retention_below_minimum" {
  command = plan

  variables {
    noncurrent_version_expiration_days = 7
  }

  expect_failures = [var.noncurrent_version_expiration_days]
}

run "rejects_non_cmk_key" {
  command = plan

  variables {
    kms_key_arn = "alias/aws/s3"
  }

  expect_failures = [var.kms_key_arn]
}
