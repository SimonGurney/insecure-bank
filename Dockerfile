FROM gradle:7.3.1-jdk17 AS builder
LABEL maintainer="Hdiv Security"

COPY --chown=gradle:gradle ./log4j-cve-2021-44228 /home/gradle/src
WORKDIR /home/gradle/src
RUN gradle :malicious-server:bootJar --no-daemon

FROM maven:3.8.6-openjdk-8 as maven
COPY . /home/app
WORKDIR /home/app
RUN mvn clean package

FROM openjdk:8u181-jdk-alpine

RUN mkdir /app
COPY --from=builder /home/gradle/src/malicious-server/build/libs/*.jar /app/malicious-server.jar

RUN mkdir -p /usr/local/tomcat/

WORKDIR /usr/local/tomcat
RUN wget --no-check-certificate https://apache.root.lu/tomcat/tomcat-8/v8.5.93/bin/apache-tomcat-8.5.93.tar.gz
RUN tar xvfz apache*.tar.gz
RUN mv apache-tomcat-8.5.93/* /usr/local/tomcat/.

ADD start.sh /usr/local/tomcat/

# Copy the application to tomcat
COPY --from=maven /home/app/target/insecure-bank.war /usr/local/tomcat/webapps/insecure-bank.war

# # Copy the license file
# ADD license.hdiv /usr/local/tomcat/hdiv/

# # Copy the agent jar
# ADD hdiv-ee-agent.jar /usr/local/tomcat/hdiv/

# Run Tomcat and enjoy!
CMD export JAVA_OPTS="-javaagent:hdiv/hdiv-ee-agent.jar \
  -Dhdiv.config.dir=hdiv/ \
  -Dhdiv.console.url=http://console:8080/hdiv-console-services \
  -Dhdiv.console.token=04db250da579302ca273a958 \
  -Dhdiv.server.name=Testing-Docker \
  -Dhdiv.toolbar.enabled=true" && ./start.sh
