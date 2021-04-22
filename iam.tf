resource "aws_iam_role" "bootstrap_role" {
  name = "vmseries_bootstrap_role_${random_string.unique_id.result}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
      "Service": "ec2.amazonaws.com"
    },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Create amn IAM Role Policy for Bootstrap & CloudWatch

resource "aws_iam_role_policy" "policy" {
  name = "vmseries_policy_${random_string.unique_id.result}"
  role = aws_iam_role.bootstrap_role.id

  policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.bucket[0].bucket}"
    },
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.bucket[0].bucket}/*"
    },
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.bucket[1].bucket}"
    },
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.bucket[1].bucket}/*"
    },
    {
      "Effect": "Allow",
      "Action": "cloudwatch:PutMetricData",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AttachNetworkInterface",
        "ec2:DetachNetworkInterface",
        "ec2:DescribeInstances",
        "ec2:DescribeNetworkInterfaces",
        "ec2:AssignPrivateIpAddresses",
        "ec2:ReplaceRoute",
        "ec2:AssociateAddress",
        "ec2:DescribeRouteTables",
        "iam:GetPolicyVersion",
        "iam:GetPolicy",
        "iam:ListAttachedRolePolicies",
        "iam:ListRolePolicies",
        "iam:GetRolePolicy",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ec2:ReplaceRoute",
      "Resource": "arn:aws:ec2:*:*:route-table/*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "bootstrap_profile" {
  name = "ngfw_bootstrap_profile_${random_string.unique_id.result}"
  role = aws_iam_role.bootstrap_role.name
  path = "/"
}
