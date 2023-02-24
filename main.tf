terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.53.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  access_key = "AKIASRECGLQV727NLNMQ"
  secret_key = "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"
}

#********************S3 Bucket*********************
resource "aws_s3_bucket" "s3-bucket" {
  bucket = "terraform-test-bucket-233348"

  tags = {
    Name        = "My bucket23"
    Environment = "Dev"
  }
}


resource "aws_s3_bucket_acl" "s3-bucket-acl" {
  bucket = aws_s3_bucket.s3-bucket.id
  acl    = "private"
}

# Create a DynamoDB table to lock the Terraform state
resource "aws_dynamodb_table" "terraform_lock" {
  name           = "terraform-state-lock"
  hash_key       = "LockID"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "LockID"
    type = "S"
  }
}

#********************VPC****************************
resource "aws_vpc" "my_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "External-VPC"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Prd-sub-1"
  }
}

#Netwrk Interface

resource "aws_network_interface" "foo" {
  subnet_id   = aws_subnet.my_subnet.id
  private_ips = ["172.16.10.100"]

  tags = {
    Name = "primary_network_interface"
  }
}




resource "aws_ec2_transit_gateway" "tras-gw" {
  description = "example"
}

#************************** Security Group **************************

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description      = "TLS from VPC 1"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.my_vpc.cidr_block]
     }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}
# Compute instance


#************************** EC2 Instance **************************
resource "aws_instance" "terraform-ec2-instance-1" {
  ami           = "ami-03c1fac8dd915ff60" 
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
   tags = {
    Name        = "My EC2 Instance-1"
    Environment = "Production"
  }
 subnet_id = aws_subnet.my_subnet.id
  
}