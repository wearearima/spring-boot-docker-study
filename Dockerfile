FROM openjdk:8-jdk-alpine
VOLUME /tmp
ARG JAR_FILE
COPY ${JAR_FILE} app.jar
EXPOSE 8080
CMD /usr/bin/java -jar app.jar -Djava.security.egd=file:/dev/./urandom
