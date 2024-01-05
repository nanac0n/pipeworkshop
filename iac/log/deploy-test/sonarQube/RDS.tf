resource "aws_db_subnet_group" "sonarqube_subnet_group" {
  name       = "sonarqube_subnet_group"
  subnet_ids = [aws_subnet.sonarqube_private_subnet_2a.id, aws_subnet.sonarqube_private_subnet_2b.id, aws_subnet.sonarqube_private_subnet_2c.id]

  tags = {
    Name = "sonarqube_subnet_group"
  }
}
resource "aws_rds_cluster" "sonarqube_db" {
  cluster_identifier            = "sonarqube1"
  engine                        = "aurora-postgresql"
  port                          = "5432"
  database_name                 = "sonarqube"
  master_username               = "sonarqube"
  backup_retention_period       = 5
  preferred_backup_window       = "07:00-09:00"
  db_subnet_group_name          = aws_db_subnet_group.sonarqube_subnet_group.id
  manage_master_user_password   = true
  skip_final_snapshot           = true
  master_user_secret_kms_key_id = aws_kms_key.sonarqube_key.key_id
  vpc_security_group_ids        = [aws_security_group.sonarqube_db.id]
}

resource "aws_rds_cluster_instance" "sonarqube_instances" {
  count              = 1
  identifier         = "sonarqube-cluster-${count.index}"
  cluster_identifier = aws_rds_cluster.sonarqube_db.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.sonarqube_db.engine
  engine_version     = aws_rds_cluster.sonarqube_db.engine_version
}

data "aws_secretsmanager_secret" "cluster_secret" {
  arn = aws_rds_cluster.sonarqube_db.master_user_secret[0].secret_arn
}
