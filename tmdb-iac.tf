provider "aws" {
  region = "us-west-2"
}

resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = file("${path.module}/keys/tmdb_key.pub")
}

resource "aws_security_group" "allow_ssh" {
  name_prefix = "allow_ssh"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # For security, consider restricting this to your IP
  }
  
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami           = "ami-074be47313f84fa38"  # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.allow_ssh.name]

  tags = {
    Name = "NginxServer"
  }



 user_data = <<-EOF
              #!/bin/bash
              echo "Starting user data script" > /tmp/user-data.log
              dnf update -y >> /tmp/user-data.log 2>&1
              dnf install -y docker nginx git >> /tmp/user-data.log 2>&1
              systemctl start docker >> /tmp/user-data.log 2>&1
              systemctl enable docker >> /tmp/user-data.log 2>&1
              usermod -aG docker ec2-user >> /tmp/user-data.log 2>&1
              systemctl start nginx >> /tmp/user-data.log 2>&1
              systemctl enable nginx >> /tmp/user-data.log 2>&1
              git clone https://github.com/salawadhi/tmdb-devops-challenge.git /tmp/tmdb-devops-challenge >> /tmp/user-data.log 2>&1
              if [ -f /tmp/tmdb-devops-challenge/nginx.conf ]; then
                cp /tmp/tmdb-devops-challenge/nginx.conf /etc/nginx/nginx.conf >> /tmp/user-data.log 2>&1
                systemctl restart nginx >> /tmp/user-data.log 2>&1
              fi
              echo "User data script completed" >> /tmp/user-data.log
              EOF

   provisioner "remote-exec" {
    inline = [
      "sleep 60",  # Add a delay to ensure the instance is ready
      "sudo systemctl stop nginx",  # Stop host's Nginx service to free up port 80
      "sudo docker run -d -p 80:80 --name nginx-container nginx",
      "sudo docker exec nginx-container bash -c 'apt-get update && apt-get install -y git'",
      "sudo docker exec nginx-container bash -c 'git clone https://github.com/salawadhi/tmdb-devops-challenge.git /usr/share/nginx/html/tmdb-devops-challenge'",
      "sudo docker exec nginx-container bash -c 'ls -la /usr/share/nginx/html/tmdb-devops-challenge'"  # List files in the directory
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
  }

  provisioner "local-exec" {
    command = "echo 'Instance is ready'"
    when    = "create"
  }
}

output "instance_ip" {
  description = "The public IP of the web server"
  value       = aws_instance.web.public_ip
}