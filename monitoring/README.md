Prometheus Monitoring and Flask Setup with Terraform and Ansible
This repository contains a Terraform configuration and an Ansible playbook to set up a Prometheus monitoring stack and a Flask application on EC2 instances.

Prerequisites
Terraform: Install Terraform on your local machine. Download Terraform
Ansible: Install Ansible on your local machine. Ansible Installation Guide
AWS CLI: Configure the AWS CLI with your credentials. AWS CLI Installation Guide
Steps to Set Up
1. Terraform Configuration
The main.tf file contains the Terraform configuration to create EC2 instances for Prometheus and Flask.

1.1 Configure main.tf
Ensure your main.tf includes the necessary resources:

hcl

provider "aws" {
  region = "us-west-2"
}

resource "aws_security_group" "allow_ssh_and_http" {
  name        = "allow_ssh_and_http"
  description = "Allow SSH and HTTP traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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
    description = "Flask App"
    from_port   = 5000
    to_port     = 5000
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
    Name = "allow_ssh_and_http"
  }
}

resource "aws_key_pair" "generated_key" {
  key_name   = "generated_key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "prometheus" {
  ami           = "ami-0c55b159cbfafe1f0"  # Replace with a valid Ubuntu AMI ID for your region
  instance_type = "t2.micro"
  key_name      = aws_key_pair.generated_key.key_name

  security_groups = [aws_security_group.allow_ssh_and_http.name]

  tags = {
    Name = "prometheus-instance"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y python3",
      "sudo ln -s /usr/bin/python3 /usr/bin/python"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
}

resource "aws_instance" "flask" {
  ami           = "ami-0c55b159cbfafe1f0"  # Replace with a valid Ubuntu AMI ID for your region
  instance_type = "t2.micro"
  key_name      = aws_key_pair.generated_key.key_name

  security_groups = [aws_security_group.allow_ssh_and_http.name]

  tags = {
    Name = "flask-instance"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y python3",
      "sudo ln -s /usr/bin/python3 /usr/bin/python"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
}

output "prometheus_public_ip" {
  value = aws_instance.prometheus.public_ip
}

output "flask_public_ip" {
  value = aws_instance.flask.public_ip
}
1.2 Apply Terraform Configuration
Initialize and apply the Terraform configuration:



terraform init
terraform apply
Note the public IPs of the Prometheus and Flask instances from the output.

2. Ansible Playbook
The install_prometheus_flask.yml playbook installs and configures Prometheus and Flask on their respective instances.

2.1 Create install_prometheus_flask.yml
yaml

---
- name: Install Prometheus and Flask
  hosts: all
  become: yes
  vars:
    ansible_python_interpreter: /usr/bin/python3
  tasks:
    - name: Install dependencies on Debian-based systems
      apt:
        name: ['wget', 'tar', 'curl', 'python3-pip']
        state: present
        update_cache: yes

    - name: Install Prometheus
      shell: |
        wget https://github.com/prometheus/prometheus/releases/download/v2.30.3/prometheus-2.30.3.linux-amd64.tar.gz
        tar -xvf prometheus-2.30.3.linux-amd64.tar.gz
        sudo mv prometheus-2.30.3.linux-amd64 /usr/local/bin/prometheus

    - name: Create Prometheus service
      copy:
        content: |
          [Unit]
          Description=Prometheus
          Wants=network-online.target
          After=network-online.target

          [Service]
          User=root
          ExecStart=/usr/local/bin/prometheus/prometheus --config.file=/usr/local/bin/prometheus/prometheus.yml

          [Install]
          WantedBy=default.target
        dest: /etc/systemd/system/prometheus.service
        mode: '0644'

    - name: Enable and start Prometheus
      systemd:
        name: prometheus
        enabled: yes
        state: started

    - name: Install Flask
      pip:
        name: flask
        state: present
        executable: pip3

    - name: Create a Flask app
      copy:
        content: |
          from flask import Flask

          app = Flask(__name__)

          @app.route('/')
          def hello_world():
              return 'Hello, World!'

          if __name__ == '__main__':
              app.run(host='0.0.0.0')
        dest: /home/ubuntu/app.py
        mode: '0755'

    - name: Create a systemd service for Flask app
      copy:
        content: |
          [Unit]
          Description=Flask App
          After=network.target

          [Service]
          User=ubuntu
          WorkingDirectory=/home/ubuntu
          ExecStart=/usr/bin/python3 /home/ubuntu/app.py

          [Install]
          WantedBy=multi-user.target
        dest: /etc/systemd/system/flask.service
        mode: '0644'

    - name: Enable and start Flask app
      systemd:
        name: flask
        enabled: yes
        state: started
2.2 Update Ansible Inventory
Create an inventory file hosts with the public IPs of the instances:

csharp

[prometheus]
<prometheus_public_ip>

[flask]
<flask_public_ip>
Replace <prometheus_public_ip> and <flask_public_ip> with the actual IP addresses.

2.3 Run the Ansible Playbook
Run the playbook to install and configure Prometheus and Flask:



ansible-playbook -i hosts --private-key ~/.ssh/id_rsa install_prometheus_flask.yml
3. Verify the Setup
3.1 Access Prometheus
Open your web browser and navigate to:

ansible-playbook -i 34.213.158.91, --private-key id_rsa -u ec2-user bootstrap.yml


http://<prometheus_public_ip>:9090
3.2 Access Flask App
Open your web browser and navigate to:


