# terraform-aws-hardened-s3

Opinionated hardened S3 bucket for EU workloads. The security posture is **not configurable**
— that is the point:

- Encryption always `aws:kms` with a **customer-managed key** (the variable is required;
  there is no AWS-managed-key fallback)
- Versioning always on; noncurrent versions retained >= 30 days
- All four Block Public Access flags on; ACLs disabled (`BucketOwnerEnforced`)
- Bucket policy denies any request over plain HTTP
- Mandatory `data_classification` tag (fixed vocabulary) and `data_residency = "eu"` label
- Lifecycle baseline: abort incomplete multiparts, expire old noncurrent versions
- Optional S3 server access logging

## Usage

```hcl
module "data_bucket" {
  source  = "terrasov/hardened-s3/aws"
  version = "~> 1.0"

  bucket_name         = "acme-prod-customer-data"
  kms_key_arn         = aws_kms_key.data.arn
  data_classification = "confidential"
  access_log_bucket   = module.log_bucket.bucket_id
}
```

Tests: native `terraform test` with a mocked provider — `terraform -chdir=. test`.

## Compliance mapping (the paid layer)

This module is the generic core of [TerraSov](https://terrasov.dev)'s `s3-secure`. The
subscription version adds what auditors actually ask for:

- Per-resource annotations mapping every setting to **ISO 27001:2022, BSI C5:2020,
  ENS (RD 311/2022) and GDPR** clauses, verified against the official texts
- Custom Checkov policies + a CI gate that **blocks PRs** with control-referenced comments
- Per-framework auditor evidence guides (annotation → policy report → AWS CLI evidence)
- 7 more modules covering org guardrails (EU region-lock SCPs), audit trail with Object
  Lock, IAM/network baselines and RDS

## License

Apache-2.0
