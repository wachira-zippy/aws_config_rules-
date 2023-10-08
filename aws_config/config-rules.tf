data "aws_iam_policy_document" "aws_config_policy" {

  statement {
    sid    = "AWSConfigBucketPermissionsCheck"
    effect = "Allow"
    actions = [
      "s3:GetBucketAcl",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.config_logs_bucket}"
    ]
  }

  statement {
    sid    = "AWSConfigBucketExistenceCheck"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.config_logs_bucket}"
    ]
  }

  statement {
    sid     = "AWSConfigBucketDelivery"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      format("arn:%s:s3:::%s%s%s/AWSLogs/%s/Config/*",
        data.aws_partition.current.partition,
        var.config_logs_bucket,
        var.config_logs_prefix == "" ? "" : "/",
        var.config_logs_prefix,
        data.aws_caller_identity.current.account_id
      )
    ]

    condition {
      test     = "StringLike"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

data "aws_iam_policy_document" "aws_config_role_policy" {

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "config_role" {
  name               = "${var.config_name}_role"
  assume_role_policy = data.aws_iam_policy_document.aws_config_role_policy.json
}

resource "aws_iam_role_policy_attachment" "managed_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_iam_policy" "aws_config_policy" {
  name   = "${var.config_name}-policy"
  policy = data.aws_iam_policy_document.aws_config_policy.json
}

resource "aws_iam_role_policy_attachment" "aws_config_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = aws_iam_policy.aws_config_policy.arn
}

resource "aws_config_configuration_recorder_status" "recorder" {
  name       = var.config_name
  is_enabled = var.is_enabled
  depends_on = [aws_config_delivery_channel.recorder]
}

resource "aws_config_delivery_channel" "recorder" {
  name           = var.config_name
  s3_bucket_name = var.config_logs_bucket
  s3_key_prefix  = var.config_logs_prefix

  snapshot_delivery_properties {
    delivery_frequency = var.config_delivery_frequency
  }
  depends_on = [aws_config_configuration_recorder.recorder]
}

resource "aws_config_configuration_recorder" "recorder" {
  name     = var.config_name
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = var.include_global_resource_types
  }
}

//get the names of the rules from the aws config console 

//EBS
resource "aws_config_config_rule" "ebs_backup" {
    name = "ebs_backup"
    source {
      owner = "AWS"
      source_identifier = "EBS_IN_BACKUP_PLAN"
    }
    depends_on = [aws_config_configuration_recorder.recorder]
}

resource "aws_config_config_rule" "ebs_encryption" {
    name = "ebs_encryption"
    source {
      owner = "AWS"
      source_identifier = "EC2_EBS_ENCRYPTION_BY_DEFAULT"
    }
    depends_on = [aws_config_configuration_recorder.recorder]
}

//IAM
resource "aws_config_config_rule" "iam_group_users" {
    name = "iam_group_users"
    source {
      owner = "AWS"
      source_identifier = "IAM_GROUP_HAS_USERS_CHECK"
    }
    depends_on = [aws_config_configuration_recorder.recorder]
}

resource "aws_config_config_rule" "iam_inline_policy" {
    name = "iam_inline_policy"
    source {
      owner = "AWS"
      source_identifier = "IAM_NO_INLINE_POLICY_CHECK"
    }
    depends_on = [aws_config_configuration_recorder.recorder]
}

resource "aws_config_config_rule" "iam_password_policy" {
    name = "iam_password_policy"
    source {
      owner = "AWS"
      source_identifier = "IAM_PASSWORD_POLICY"
    }
    depends_on = [aws_config_configuration_recorder.recorder]
}

resource "aws_config_config_rule" "iam_group_membership" {
    name = "iam_group_membership"
    source {
      owner = "AWS"
      source_identifier = "IAM_USER_GROUP_MEMBERSHIP_CHECK"
    }
    depends_on = [aws_config_configuration_recorder.recorder]
}

resource "aws_config_config_rule" "iam_user_mfa" {
    name = "iam_user_mfa_enabled"
    source {
      owner = "AWS"
      source_identifier = "IAM_USER_MFA_ENABLED"
    }
    depends_on = [aws_config_configuration_recorder.recorder]
}