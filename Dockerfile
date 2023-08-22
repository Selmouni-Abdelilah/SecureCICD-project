FROM tomcat:8-jre8-slim
RUN rm -rf /usr/local/tomcat/webapps/*
COPY target/library-0.0.1-SNAPSHOT.war /usr/local/tomcat/webapps/myproject.war
EXPOSE 8080
CMD ["catalina.sh","run"]
