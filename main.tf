provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_instance" "nat_a" {

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.amazon_nat_ami, var.aws_region)}"

  /*subnet_id = "${aws_subnet.search_public_a.id}"*/
  associate_public_ip_address = "true"
  /*security_groups = ["${aws_security_group.nat.id}"]*/
  key_name = "${var.key_name}"
  count = "1"

  connection {
    # The default username for our AMI
    user = "ec2-user"
    type = "ssh"
    host = "${self.private_ip}"
    # The path to your keyfile
    key_file = "${var.key_path}"
  }

  tags {
    Name = "exprimental-2"
  }

}
