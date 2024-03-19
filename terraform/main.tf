provider "aws" {
  region = "us-west-1"
}

/*
=================================================================
Create S3 bucket and Cloudfront distribution for static website hosting 
=================================================================
*/

resource "aws_s3_bucket" "wordtrendlearner_frontend" {
  bucket = "wordtrendlearner_frontend"
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.wordtrendlearner_frontend.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.wordtrendlearner_frontend.id}/*",
        "arn:aws:s3:::${aws_s3_bucket.wordtrendlearner_frontend.id}"
      ]
    }]
  })
}

resource "aws_s3_bucket_website_configuration" "wordtrendlearner_frontend" {
  bucket = aws_s3_bucket.wordtrendlearner_frontend.id

  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}


resource "aws_cloudfront_distribution" "static_website_distribution" {
  origin {
    domain_name = aws_s3_bucket.wordtrendlearner_frontend.bucket_regional_domain_name
    origin_id   = "S3Origin"
  }

  enabled             = true
  default_root_object = "index.html"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
  }

  viewer_certificate {
    cloudfront_default_certificate = true  # Replace with custom SSL certificate ARN if needed
  }
}

# Output the CloudFront domain name for accessing the website
output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.static_website_distribution.domain_name
}

/*
=================================================================
Create S3 bucket used for storage of predictive word bank 
=================================================================
*/