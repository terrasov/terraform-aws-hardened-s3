variable "bucket_name" {
  description = "Globally unique bucket name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 chars, lowercase letters, digits, dots or hyphens."
  }
}

variable "kms_key_arn" {
  description = "ARN of the KMS customer-managed key used for default encryption. AWS-managed keys are deliberately not supported."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:kms:[a-z0-9-]+:\\d{12}:key/", var.kms_key_arn))
    error_message = "kms_key_arn must be a KMS key ARN (arn:aws:kms:<region>:<account>:key/<id>)."
  }
}

variable "data_classification" {
  description = "Classification of the data stored in this bucket."
  type        = string

  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "data_classification must be one of: public, internal, confidential, restricted."
  }
}

variable "access_log_bucket" {
  description = "Name of the bucket receiving S3 server access logs. Strongly recommended in production; the terrasov-gate policy set enforces it at the root configuration."
  type        = string
  default     = null
}

variable "access_log_prefix" {
  description = "Key prefix for delivered access log objects."
  type        = string
  default     = "s3-access/"
}

variable "noncurrent_version_expiration_days" {
  description = "Days to retain noncurrent object versions before expiration."
  type        = number
  default     = 90

  validation {
    condition     = var.noncurrent_version_expiration_days >= 30
    error_message = "noncurrent_version_expiration_days must be >= 30."
  }
}

variable "abort_incomplete_multipart_days" {
  description = "Days after initiation to abort incomplete multipart uploads."
  type        = number
  default     = 7
}

variable "force_destroy" {
  description = "Allow bucket deletion with objects present. Keep false for production data."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags merged onto all resources. data_classification and data_residency are always set by the module and cannot be overridden."
  type        = map(string)
  default     = {}
}
