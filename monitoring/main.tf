provider "aws" {
  region = "us-west-2"
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = file("${path.module}/keys/id_rsa.pub")
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH and HTTP inbound traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Node Exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Alertmanager"
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Flask App"
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_instance" "example" {
  ami           = "ami-074be47313f84fa38"  
  instance_type = "t2.micro"
  key_name      = aws_key_pair.generated_key.key_name

  security_groups = [aws_security_group.allow_ssh.name]

  tags = {
    Name = "example-instance"
  }

  provisioner "remote-exec" {
    inline = [
      "if [ -x /usr/bin/apt-get ]; then sudo apt-get update && sudo apt-get install -y ansible; elif [ -x /usr/bin/yum ]; then sudo yum update -y && sudo yum install -y ansible; else echo 'Unsupported package manager'; fi"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }
}

output "instance_public_ip" {
  value = aws_instance.example.public_ip
}
