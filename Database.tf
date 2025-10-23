resource "aws_db_instance" "database" {
  identifier             = "mydb"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "Webappdb"
  username               = "admin"
  password               = "Password"
  skip_final_snapshot    = true
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.Database-SG.id]
  db_subnet_group_name   = aws_db_subnet_group.db-subnet.name
}
