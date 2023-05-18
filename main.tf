provider "aws" {
  region = "us-east-1"
  access_key = "access key"
  secret_key = "secret key"

}

# Define variables
variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "ebs_volume_size" {
  description = "EBS volume size (in GB)"
  default     = 10
}

# Create EC2 instance
resource "aws_instance" "ec2_instance" {
  ami           = "ami-xxxxxxxx"  # Specify the desired AMI ID
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_subnet.id

  tags = {
    Name = "MyEC2Instance"
  }
}

# Attach EBS volume to EC2 instance
resource "aws_volume_attachment" "ebs_attachment" {
  device_name = "/dev/xvdf"  # Adjust the device name as needed
  volume_id   = aws_ebs_volume.ebs_volume.id
  instance_id = aws_instance.ec2_instance.id
}

# Create and run a user data script to upload and execute the Python program
resource "aws_instance" "ec2_instance" {
  ami           = "ami-xxxxxxxx"  # Specify the desired AMI ID
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_subnet.id

  user_data = <<-EOF
    #!/bin/bash
    aws s3 cp s3://your-bucket-name/your-python-program.py /home/ec2-user/your-python-program.py
    python /home/ec2-user/your-python-program.py
    EOF

  tags = {
    Name = "MyEC2Instance"
  }
}

# Create a Python program file
data "template_file" "python_program" {
  template = file("${path.module}/python_program.py")
}

# Upload the Python program file to S3
resource "aws_s3_bucket_object" "python_program" {
  bucket = aws_s3_bucket.s3_bucket.id
  key    = "your-python-program.py"
  source = data.template_file.python_program.rendered
}

# Create an S3 bucket
resource "aws_s3_bucket" "s3_bucket" {
  bucket = "your-bucket-name"
}

# Provide list permission to the EC2 instance on the S3 bucket
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.s3_bucket.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowListAccess",
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
          "s3:ListBucket"
        ],
        "Resource": [
          "arn:aws:s3:::your-bucket-name"
        ],
        "Condition": {
          "StringEquals": {
            "aws:SourceVpc": aws_subnet.private_subnet.vpc_id
          }
        }
      },
      {
        "Sid": "AllowObjectAccess",
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
          "s3:GetObject"
        ],
        "Resource": [
          "arn:aws:s3:::your-bucket-name/*"
        ],
        "Condition": {
          "StringEquals": {
            "aws:SourceVpc": aws_subnet.private_subnet.vpc_id
          }
        }
      }
    ]
  })
}

# Create a private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "us-west-2a"  # Adjust the availability
