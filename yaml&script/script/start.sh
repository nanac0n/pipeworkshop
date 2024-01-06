#!/bin/bash
#cd /home/ubuntu/server/target/
#java -jar webgoat-2023.6-SNAPSHOT.jar --server.port=8080 --server.address=13.125.55.184 

CURRENT_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
BUILD_JAR=$(ls /home/ubuntu/*.jar)
JAR_NAME=$(basename "$BUILD_JAR")
echo "> build 파일명: $JAR_NAME" >> /home/ubuntu/deploy.log

echo "> build 파일 복사" >> /home/ubuntu/deploy.log
DEPLOY_PATH=/home/ubuntu/
cp "$BUILD_JAR" $DEPLOY_PATH

echo "> 현재 실행중인 애플리케이션 pid 확인" >> /home/ubuntu/deploy.log
CURRENT_PID=$(pgrep -f "$JAR_NAME")

if [ -z "$CURRENT_PID" ]
then
  echo "> noting to kill" >> /home/ubuntu/deploy.log
else
  echo "> kill -15 $CURRENT_PID"
  kill -15 "$CURRENT_PID"
  sleep 5
fi

DEPLOY_JAR=$DEPLOY_PATH$JAR_NAME
echo "> MONGO_URL:"
echo "$MONGO_URL"
echo "> run DEPLOY_JAR"    >> /home/ubuntu/deploy.log

nohup java -jar "$DEPLOY_JAR" --server.port=8080 --server.address=$CURRENT_IP > /dev/null 2> /dev/null < /dev/null &

#nohup java -jar "$DEPLOY_JAR" --server.port=8080 --server.address=13.125.55.184 &