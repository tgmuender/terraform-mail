provider "aws" {
    region = "${var.aws_region}"
}

# SSH key pair
resource "aws_key_pair" "mail-ssh-keys" {
  key_name = "default-key"
  public_key = "${var.ssh-pubkey}"
}

 # EC2 instance
 resource "aws_instance" "mail-host" {
     ami = "${data.aws_ami.ubuntu.id}"
     instance_type = "t2.micro"
     key_name = "${aws_key_pair.mail-ssh-keys.key_name}"
     security_groups = ["mail-group"]

     provisioner "file" {
       source = "mail-setup.sh"
       destination = "/tmp/mail-setup.sh"

      connection {
        type = "ssh"
        user = "ubuntu"
        private_key = "${file("${path.module}/keys/id_rsa")}"
      }
     }

     provisioner "remote-exec" {
        connection {
            type = "ssh"
            user = "ubuntu"
            private_key = "${file("${path.module}/keys/id_rsa")}"
        }

        inline = [
          "sudo chmod u+x /tmp/mail-setup.sh",
          "sudo /tmp/mail-setup.sh ${var.salt-master}"
        ]
    }
 }

# Machine image
 data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# Security Group
resource "aws_security_group" "mail-group" {
    name = "mail-group"
    description = "Mail server rules"

    ingress {        
        from_port   = 22
        to_port     = 22
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