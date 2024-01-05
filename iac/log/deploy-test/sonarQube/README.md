# sonarqube_aws_terraform

`terraform init`

`terraform apply`

ECR PUSH sonarqube docker image
1. `docker pull sonarqube:latest`
2. `aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <accountID>.dkr.ecr.<region>.amazonaws.com`
3. `docker tag sonarqube:latest <accountID>.dkr.ecr.<region>.amazonaws.com/sonarqube:latest`
4. `docker push <accountID>.dkr.ecr.<region>.amazonaws.com/sonarqube:latest`

Connect to port 9000 of the load balancer DNS. ( xxxxxx.xxxxxx.amazonaws.com:9000 )

done.
