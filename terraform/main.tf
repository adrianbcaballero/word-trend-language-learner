provider "aws" {
  region = "us-west-1"
}

/*
=================================================================
Create S3 bucket and Cloudfront distribution for static website hosting 
=================================================================
*/

resource "aws_s3_bucket" "wordtrendlearner_frontend" {
  bucket = "wordtrendlearner-frontend"
}

resource "aws_s3_bucket_ownership_controls" "wordtrendlearner_frontend" {
  bucket = aws_s3_bucket.wordtrendlearner_frontend.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "wordtrendlearner_frontend" {
  bucket = aws_s3_bucket.wordtrendlearner_frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "wordtrendlearner_frontend" {
  depends_on = [
    aws_s3_bucket_ownership_controls.wordtrendlearner_frontend,
    aws_s3_bucket_public_access_block.wordtrendlearner_frontend,
  ]

  bucket = aws_s3_bucket.wordtrendlearner_frontend.id
  acl    = "public-read-write"
}

data "aws_iam_policy_document" "origin" {
  depends_on = [
    aws_cloudfront_distribution.Site_Access,
    aws_s3_bucket.wordtrendlearner_frontend
  ]

  statement {
    sid    = "3"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type        = "Service"
    }
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.wordtrendlearner_frontend.bucket}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"

      values = [
        aws_cloudfront_distribution.Site_Access.arn
      ]
    }
  }
}


resource "aws_cloudfront_distribution" "Site_Access" {
  depends_on = [
    aws_s3_bucket.wordtrendlearner_frontend,
    aws_cloudfront_origin_access_control.Site_Access
  ]

  origin {
    domain_name              = aws_s3_bucket.wordtrendlearner_frontend.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.wordtrendlearner_frontend.id
    origin_access_control_id = aws_cloudfront_origin_access_control.Site_Access.id
  }

  enabled             = true
  default_root_object = "website_page.html"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.wordtrendlearner_frontend.id
    viewer_protocol_policy = "https-only"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }

    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


resource "aws_cloudfront_origin_access_control" "Site_Access" {
  name                              = "Security_Pillar100_CF_S3_OAC"
  description                       = "OAC setup for security pillar 100"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

/*
=================================================================
Create S3 bucket used for storage of predictive word bank 
=================================================================
*/

resource "aws_s3_bucket" "wordbank" {
  bucket = "wordtrendlearner-wordbank"
}

resource "aws_s3_bucket_ownership_controls" "wordbank" {
  bucket = aws_s3_bucket.wordbank.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "wordbank" {
  bucket = aws_s3_bucket.wordbank.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_access" {
  bucket = aws_s3_bucket.wordbank.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action   = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject", 
        ],
        Resource = [
          "${aws_s3_bucket.wordbank.arn}",
          "${aws_s3_bucket.wordbank.arn}/*",
        ]
      },
      {
        Effect   = "Allow",
        Principal = {
          Service = "glue.amazonaws.com"
        },
        Action   = "s3:GetObject",
        Resource = [
          "${aws_s3_bucket.wordbank.arn}",
          "${aws_s3_bucket.wordbank.arn}/*",
        ]
      }
    ]
  })
}

/*
=================================================================
Set up AWS Clue to defina table schema on S3 word bank
=================================================================
*/

resource "aws_glue_catalog_database" "glue_database" {
  name = "word_bank_datase"
}

resource "aws_glue_catalog_table" "glue_table" {
  name          = "random_words"
  database_name = aws_glue_catalog_database.glue_database.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "csv"
  }

  storage_descriptor {
    location      = "s3://wordtrendlearner-wordbank/random_words/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.OpenCSVSerde"

      parameters = {
        "skip.header.line.count" = "1"
        "separatorChar" = ","
      }
    }

    columns {
      name = "id_num"
      type = "int"
    }

    columns {
      name = "word"
      type = "string"
    }
  }
}

/*
====================================================================
Creating Lambda function that returns new word on request and on web access
====================================================================
*/

//lambda function triggered by api gateway
data "archive_file" "new-word-lambda" {
  type = "zip"
  source_file = "${path.module}/../../src/backend/api-lambda/new-word-lambda.py"
  output_path = "lambda-new-word.zip"
  output_file_mode = 0666
}

resource "aws_iam_role" "lambda_role" {
  name               = "Lambda_Function_Role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_full_access_policy" {
  name        = "lambda_full_access_policy"
  description = "Policy for full access to s3 bucket, athena, cloudwatch, glue, and api gateway"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:*",
          "apigateway:*",
          "cloudfront:*",
          "lambda:*",
          "athena:*",
          "glue:*",
          "s3:*"
        ],
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_full_access_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_full_access_policy.arn
}

resource "aws_lambda_function" "get-new-word" {
  function_name = "get-new-word"
  filename = "lambda-new-word.zip"
  role = aws_iam_role.lambda_role.arn
  runtime = "python3.9"
  handler = "new-word-lambda.lambda_handler"
  source_code_hash = data.archive_file.new-word-lambda.output_base64sha256
}

resource "aws_lambda_permission" "allow_api_gateway_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:*"
  function_name = aws_lambda_function.get-new-word.arn
  principal     = "apigateway.amazonaws.com"
}
