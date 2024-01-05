resource "aws_ecs_task_definition" "sonarqube" {
  family                   = "sonarqube"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "3072"
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  task_role_arn      = aws_iam_role.SonarQubeTaskRole.arn
  execution_role_arn = aws_iam_role.SonarQubeTaskExecutionRole.arn
  volume {
    name = "sonarqube_data"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.sonarqube_efs.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.sonarqube_data.id
        iam             = "DISABLED"
      }
    }
  }
  volume {
    name = "sonarqube_extensions"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.sonarqube_efs.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.sonarqube_extensions.id
        iam             = "DISABLED"
      }
    }
  }
  volume {
    name = "sonarqube_logs"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.sonarqube_efs.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.sonarqube_logs.id
        iam             = "DISABLED"
      }

    }
  }
  container_definitions = <<TASK_DEFINITION
 [
        {
            "name": "sonarqube",
            "image": "${aws_ecr_repository.sonarqube.repository_url}:latest",
            "portMappings": [
                {
                    "name": "sonarqube-9000-tcp",
                    "containerPort": 9000,
                    "hostPort": 9000,
                    "protocol": "tcp",
                    "appProtocol": "http"
                }
            ],
            "essential": true,
            "environment": [
                {
                    "name": "SONAR_JDBC_USERNAME",
                    "value": "sonarqube"
                },
                {
                    "name": "SONAR_JDBC_URL",
                    "value": "jdbc:postgresql://${aws_rds_cluster.sonarqube_db.endpoint}:5432/sonarqube"
                },
                {
                    "name": "SONAR_SEARCH_JAVAADDITIONALOPTS",
                    "value": "-Dnode.store.allow_mmap=false,-Ddiscovery.type=single-node"
                }
            ],
            "mountPoints": [
                {
                    "sourceVolume": "sonarqube_data",
                    "containerPath": "/opt/sonarqube/data",
                    "readOnly": false
                },
                {
                    "sourceVolume": "sonarqube_extensions",
                    "containerPath": "/opt/sonarqube/extensions",
                    "readOnly": false
                },
                {
                    "sourceVolume": "sonarqube_logs",
                    "containerPath": "/opt/sonarqube/logs",
                    "readOnly": false
                }
            ],
            "secrets": [
                {
                    "name": "SONAR_JDBC_PASSWORD",
                    "valueFrom": "${data.aws_secretsmanager_secret.cluster_secret.arn}:password::"
                }
            ],
            "ulimits": [
                {
                    "name": "nofile",
                    "softLimit": 65535,
                    "hardLimit": 65535
                }
            ],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/sonarqube",
                    "awslogs-region": "ap-northeast-2",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]
  TASK_DEFINITION
}
resource "aws_ecs_cluster" "sonarqube" {
  name = "sonarqube2"
}
resource "aws_ecs_service" "sonarqube" {
  name            = "sonarqube"
  cluster         = aws_ecs_cluster.sonarqube.id
  task_definition = aws_ecs_task_definition.sonarqube.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.sonarqube.arn
    container_name   = "sonarqube"
    container_port   = 9000
  }
  network_configuration {
    subnets         = [aws_subnet.sonarqube_private_subnet_2a.id, aws_subnet.sonarqube_private_subnet_2b.id, aws_subnet.sonarqube_private_subnet_2c.id]
    security_groups = [aws_security_group.sonarqube_sg.id]

  }
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}
resource "aws_secretsmanager_secret" "sonarqube_db_password" {
  name_prefix = "sonarqube"
  kms_key_id  = aws_kms_key.sonarqube_key.key_id
}