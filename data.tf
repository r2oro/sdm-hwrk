data "aws_ami" "linux_ami" {
    most_recent = true
    owners      = ["amazon"]

    filter {
        name   = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
        # values = ["al2023-*-x86_64"]
    }
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

