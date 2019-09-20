# Introduction

The aim of this repo is to measure some features of an Spring Boot application and its Docker image. 
Instead of creating a new Spring Boot demo from scratch, it is based on 
[Spring PetClinic](https://github.com/spring-projects/spring-petclinic).

# Changes

We've applied some advices of [this article](https://spring.io/blog/2018/12/12/how-fast-is-spring#tldr-how-do-i-make-my-app-go-faster):

 - Disable actuators
 - Disable JMX
 - Use `slf4j-jdk14`for logging

Additionaly, we'll run the application with `mysql` profiled enabled to avoid h2 database's creation and initialization time. 

#  Size

## Spring Boot artifact's size

Build PetClinic application:

```
git clone https://github.com/wearearima/spring-boot-docker-size.git
cd spring-boot-docker-size
./mvnw clean package
```

Measure the jar files:

```
ls -lh target/*.jar*
```

Result:

```
-rw-r--r--  1 inigotelleria  staff    43M Sep  2 17:05 target/spring-petclinic-2.1.0.BUILD-SNAPSHOT.jar
-rw-r--r--  1 inigotelleria  staff   371K Sep  2 17:05 target/spring-petclinic-2.1.0.BUILD-SNAPSHOT.jar.original
```

The file named `spring-petclinic-2.1.0.BUILD-SNAPSHOT` is the resulting fat jar because it includes
PetClinic's code and its dependencies. The other file, suffixed `.original`, is just PetClinic's code
without its dependencies. The result is that our code size is `371KB` and the dependencies' `43MB`. 

## Docker image's size

Build PetClinic's Docker image:

```
./mvnw jib:dockerBuild
```

Measure the image size:

```
docker image ls | grep spring-petclinic
```

Result:

```
org.springframework.samples/spring-petclinic                     2.1.0.BUILD-SNAPSHOT                  b0379064ade1        49 years ago        136MB
```

We can see that size of the artifact has increased from `43MB` to `136MB`. This is mainly because the 
Docker image includes the JDK and Linux images. Run this command to check it:

```
docker image history org.springframework.samples/spring-petclinic
```

The result shows the different layers added to the Docker image:

```
Inigos-MacBook-Pro:spring-petclinic inigo$ docker image history org.springframework.samples/spring-petclinic
IMAGE               CREATED             CREATED BY                                      SIZE                COMMENT
e3718c1a3f02        49 years ago        jib-maven-plugin:1.5.1                          47.8kB              classes
<missing>           49 years ago        jib-maven-plugin:1.5.1                          941kB               resources
<missing>           49 years ago        jib-maven-plugin:1.5.1                          44.7MB              dependencies
<missing>           2 days ago          /bin/sh -c #(nop)  ENV JAVA_HOME=/opt/java/o…   0B                  
<missing>           2 days ago          /bin/sh -c set -eux;     apk add --no-cache …   75.7MB              
<missing>           2 days ago          /bin/sh -c #(nop) COPY multi:cf4be6a9ef2b0c0…   15.6kB              
<missing>           2 days ago          /bin/sh -c #(nop)  ENV JAVA_VERSION=jdk8u222…   0B                  
<missing>           2 days ago          /bin/sh -c apk add --no-cache --virtual .bui…   8.88MB              
<missing>           2 days ago          /bin/sh -c #(nop)  ENV LANG=en_US.UTF-8 LANG…   0B                  
<missing>           3 weeks ago         /bin/sh -c #(nop)  CMD ["/bin/sh"]              0B                  
<missing>           3 weeks ago         /bin/sh -c #(nop) ADD file:fe64057fbb83dccb9…   5.58MB
```

The `5.58MB` image is the Alpine Linux image and the `75.7MB` image is the JDK8 image. The sum of all layers results in 
an image of `136MB` which includes Linux OS, JDK8, PetClinic's code and dependencies' jar.  

> Different Linux image comparison at https://github.com/gliderlabs/docker-alpine#why 

# Startup time

Start Mysql server before running the application:

```
docker run -e MYSQL_ROOT_PASSWORD=petclinic -e MYSQL_DATABASE=petclinic -p 3306:3306 mysql:5.7.8
```

Run PetClinic application with this command:

```
java -jar  -Dspring.profiles.active=mysql target/spring-petclinic-2.1.0.BUILD-SNAPSHOT.jar
```

The applications starts en `4,3 seconds` using AdoptOpenJDK 1.8.0_222-b10:

```
Started PetClinicApplication in 4.317 seconds (JVM running for 4.976)
```

# Memory usage

After navigating through the application to make sure all beans are loaded, open `JConsole` or other profiler such as 
YourKit. Measure the heap after executing Garbage Collector (GC). 

![jconsole-result](jconsole/result.png)

With no load the application's heap consumption is around `45MB` . However, the memory consumption is bigger than just the
heap, so let's measure it using ``ps`` command:

```
Inigos-MacBook-Pro:spring-boot-docker-size inigo$ ps aux 67118
USER    PID  %CPU %MEM      VSZ    RSS   TT  STAT STARTED      TIME COMMAND
inigo    67118   0.0  3.3 10205612 561380 s000  S+    2:52PM   0:24.84 java -jar -Dspring.profiles.active=mysql target/spring-petclinic-2.1.0.BUILD-SNAPSHOT.jar
```

We can see that PetClinic's process actually is using almost `560MB` of memory.  

> Interesting resource about measuring Spring Boot: https://spring.io/blog/2015/12/10/spring-boot-memory-performance

# Summary

| Feature                                           |                   |
| ------------------------------------------------- | ----------------- |
| Spring Boot App disk usage                        | 43M               |
| Spring Boot App disk usage (without dependencies) | 371KB             |
| Docker Container disk usage                       | 136MB             |
| Spring Boot App startup time                      | 4,3 seconds       |
| Spring Boot App heap consumption                  | 45MB              |
| Spring Boot App memory usage                      | 560MB             |

# Credits

Original PetClinic by https://www.spring.io

Docker configuration by https://www.arima.eu

![ARIMA Software Design](https://arima.eu/arima-claim.png)
