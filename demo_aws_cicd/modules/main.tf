# Create codecommit repository
resource "aws_codecommit_repository" "repo" {
  repository_name = var.repo_name
  description     = var.description
  default_branch  = var.default_repo_branch
  tags            = local.module_tags
}

# Create pipeline for repo
resource "aws_codepipeline" "codepipeline" {
  name     = "${var.repo_name}-demo-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName       = var.repo_name
        BranchName           = "master"
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Tests"

    action {
      name             = "Terraform-plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output_tests"]
      version          = "1"

      configuration = {
        ProjectName   = aws_codebuild_project.build_tf_plan.id
        PrimarySource = "source_output"
      }
    }
  }

  stage {
    name = "Approval"

    action {
      name     = "Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "Terraform-apply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output_deploy"]
      version          = "1"

      configuration = {
        ProjectName   = aws_codebuild_project.build_tf_apply.id
        PrimarySource = "source_output"
      }
    }
  }
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "${var.repo_name}-artifact-bucket"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "codepipeline_bucket_acl" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  acl    = "private"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "${var.repo_name}-repo-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codecommit:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Create build jobs for the pipeline
resource "aws_codebuild_project" "build_tf_plan" {
  name          = "${var.repo_name}-terraform-plan"
  description   = "Demo build job for terraform plan"
  build_timeout = "30"
  service_role  = aws_iam_role.build_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.build_bucket.bucket
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:3.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

  }

  logs_config {
    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.build_bucket.id}/build-log-plan"
    }
  }

  source {
    type      = "CODECOMMIT"
    location  = aws_codecommit_repository.repo.clone_url_http
    buildspec = ".buildspec/terraform_plan.yml"

    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }
  }

  vpc_config {
    vpc_id = data.aws_vpc.vpc.id

    subnets = [
      element(data.aws_subnets.private.ids, 0)
    ]

    security_group_ids = [
      aws_security_group.allow_vpc_cidr.id,
    ]
  }

  tags = local.module_tags
}

resource "aws_codebuild_project" "build_tf_apply" {
  name          = "${var.repo_name}-terraform-apply"
  description   = "Demo build job for terraform plan"
  build_timeout = "30"
  service_role  = aws_iam_role.build_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.build_bucket.bucket
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:3.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

  }

  logs_config {
    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.build_bucket.id}/build-log-apply"
    }
  }

  source {
    type      = "CODECOMMIT"
    location  = aws_codecommit_repository.repo.clone_url_http
    buildspec = ".buildspec/terraform_apply.yml"

    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }
  }

  vpc_config {
    vpc_id = data.aws_vpc.vpc.id

    subnets = [
      element(data.aws_subnets.private.ids, 0)
    ]

    security_group_ids = [
      aws_security_group.allow_vpc_cidr.id,
    ]
  }

  tags = local.module_tags
}

resource "aws_s3_bucket" "build_bucket" {
  bucket = "${var.repo_name}-build-bucket"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "build_bucket_acl" {
  bucket = aws_s3_bucket.build_bucket.id
  acl    = "private"
}

resource "aws_iam_role" "build_role" {
  name = "${var.repo_name}-build-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "build_policy" {
  role = aws_iam_role.build_role.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": ["*"],
      "Action": ["*"]
    }
  ]
}
POLICY
}

data "aws_vpc" "vpc" {
  tags = {
    Environment = "dev"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
  tags = {
    SubnetType = "private"
  }
}

resource "aws_security_group" "allow_vpc_cidr" {
  name        = "${var.repo_name}-build-sg"
  description = "Allow vpc traffic"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.repo_name}-build-sg"
  }
}