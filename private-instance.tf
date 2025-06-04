# This Terraform configuration sets up a private instance in AWS.

resource "aws_security_group" "private_sg" {
    vpc_id = aws_vpc.sdm-hwrk-vpc.id
    name = "sdm-hwrk-private-sg"
    description = "Security group for private instances"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = [aws_security_group.gateway_sg.id]
        description = "Allow SSH access from jumpbox and gateway"
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all outbound traffic"
    }
    tags = {
        Name = "sdm-hwrk-private-sg"
    }
}

resource "aws_instance" "private_instance" {
    ami = data.aws_ami.linux_ami.id
    associate_public_ip_address = false
    user_data_replace_on_change = true
    instance_type = "t2.micro"
    subnet_id = aws_subnet.private_subnet.id
    vpc_security_group_ids =  [aws_security_group.private_sg.id]
    user_data = templatefile("centos-sdm.tpl.sh", {
        target_user = "ec2-user"
        sshca       = data.sdm_ssh_ca_pubkey.ssh_pubkey_query.public_key
    })
    tags = {
        Name = "sdm-hwrk-private-instance"
    }
}

# SDM resource for connecting to the private instance using SSH and the StrongDM CA public key
resource "sdm_resource" "private_instance_ssh" {
    ssh_cert {
        name = "sdm-hwrk-private-instance"
        hostname = aws_instance.private_instance.private_ip
        port = 22
        username = "ec2-user"
        tags = {
            "strongdm:private" = "true"
        }
    }
}
