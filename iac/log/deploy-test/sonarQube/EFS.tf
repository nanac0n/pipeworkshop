resource "aws_efs_file_system" "sonarqube_efs" {
  creation_token = "sonarqube-efs"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  encrypted  = true
  kms_key_id = aws_kms_key.sonarqube_key.arn
}

resource "aws_efs_access_point" "sonarqube_data" {
  file_system_id = aws_efs_file_system.sonarqube_efs.id
  posix_user {
    gid = 1000
    uid = 1000
  }
  root_directory {
    path = "/sonarqube_data"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }
}
resource "aws_efs_access_point" "sonarqube_extensions" {
  file_system_id = aws_efs_file_system.sonarqube_efs.id
  posix_user {
    gid = 1000
    uid = 1000
  }
  root_directory {
    path = "/sonarqube_extensions"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }
}
resource "aws_efs_access_point" "sonarqube_logs" {
  file_system_id = aws_efs_file_system.sonarqube_efs.id
  posix_user {
    gid = 1000
    uid = 1000
  }
  root_directory {
    path = "/sonarqube_logs"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }
}
resource "aws_efs_mount_target" "data" {
  file_system_id  = aws_efs_file_system.sonarqube_efs.id
  subnet_id       = aws_subnet.sonarqube_private_subnet_2a.id
  security_groups = [aws_security_group.sonarqube_default.id]
}
resource "aws_efs_mount_target" "extensions" {
  file_system_id  = aws_efs_file_system.sonarqube_efs.id
  subnet_id       = aws_subnet.sonarqube_private_subnet_2b.id
  security_groups = [aws_security_group.sonarqube_default.id]
}
resource "aws_efs_mount_target" "logs" {
  file_system_id  = aws_efs_file_system.sonarqube_efs.id
  subnet_id       = aws_subnet.sonarqube_private_subnet_2c.id
  security_groups = [aws_security_group.sonarqube_default.id]
}
