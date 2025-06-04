# SDM Gateway resources
#--------------------------------------------------------------

resource "aws_eip" "sdm_hwrk_gateway" {
  domain = "vpc"

  tags = {
    Name = "sdm-hwrk-gateway-eip"
  }
}

# Create a StrongDM gateway node in the control plane
resource "sdm_node" "sdm_hwrk_gateway" {
  gateway {
    name           = "sdm-hmwrk-gateway"
    listen_address = "${aws_eip.sdm_hwrk_gateway.public_dns}:5000"
    bind_address   = "0.0.0.0:5000"
  }
}

# Create an AWS key pair using the StrongDM-generated public key
resource "aws_key_pair" "sdm_hwrk_gateway" {
  key_name   = "sdm-hwrk-gateway-key"
  public_key = sdm_resource.sdm_hwrk_gateway_ssh.ssh[0].public_key # Use the public key from the StrongDM SSH resource
  tags = {
    Name = "sdm-hwrk-gateway-key"
  }
}

resource "aws_security_group" "gateway_sg" {
  name        = "sdm-hwrk-gateway-sg"
  description = "Security group for the StrongDM gateway instance"
  vpc_id      = aws_vpc.sdm-hwrk-vpc.id
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow StrongDM traffic"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self        = true
    description = "Allow SSH From SDM Gateway"
  }       
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

# Launch the EC2 instance that will run the StrongDM gateway
resource "aws_instance" "sdm_hwrk_gateway" {
  ami                         = data.aws_ami.gateway_ami.id
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  user_data_replace_on_change = true
  vpc_security_group_ids      = [aws_security_group.gateway_sg.id] # Include jumpbox security group for SSH access
  key_name                    = aws_key_pair.sdm_hwrk_gateway.key_name
  # Bootstrap the gateway using the provisioning template
  user_data = templatefile("gateway.tpl.sh", {
    sdm_relay_token = sdm_node.sdm_hwrk_gateway.gateway[0].token # Relay token for gateway registration
    target_user     = "ubuntu"                          # User to run the gateway service
  })
  tags = {
    Name = "sdm_hwrk_gateway"
  }
}

# Associate the Elastic IP with the gateway instance
resource "aws_eip_association" "gw_eip_assoc" {
  instance_id   = aws_instance.sdm_hwrk_gateway.id
  allocation_id = aws_eip.sdm_hwrk_gateway.id
}

# Register the gateway host as an SSH resource in StrongDM for administrative access
resource "sdm_resource" "sdm_hwrk_gateway_ssh" {
  ssh {
    name     = "sdm-hmwrk-gateway"
    hostname = aws_eip.sdm_hwrk_gateway.private_ip
    port     = 22
    username = "ubuntu"
    tags = {
      "strongdm:gateway" = "true" # Tag to identify this as a gateway resource
    }
  }
}
