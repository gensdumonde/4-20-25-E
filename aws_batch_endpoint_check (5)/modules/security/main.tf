resource "aws_security_group" "batch_sg" {
  name        = "batch-sg"
  description = "Allow all traffic (demo purpose)"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "batch-sg" }
}

output "security_group_id" {
  value = aws_security_group.batch_sg.id
}
