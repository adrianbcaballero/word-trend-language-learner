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


resource "aws_s3_bucket_policy" "origin" {
  depends_on = [
    aws_cloudfront_distribution.Site_Access
  ]
  bucket = aws_s3_bucket.wordtrendlearner_frontend.id
  policy = data.aws_iam_policy_document.origin.json
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