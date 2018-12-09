# Introduction

The aim of this repo is to measure some features of an Spring Boot application and its Docker image. 
Instead of creating a new Spring Boot demo from scratch, it is based on 
[Spring PetClinic](https://github.com/spring-projects/spring-petclinic).

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
-rw-r--r--  1 inigo  staff    43M Dec  9 21:59 target/spring-petclinic-2.1.0.BUILD-SNAPSHOT.jar
-rw-r--r--  1 inigo  staff   372K Dec  9 21:59 target/spring-petclinic-2.1.0.BUILD-SNAPSHOT.jar.original
```

The file named `spring-petclinic-2.1.0.BUILD-SNAPSHOT` is the resulting fat jar because it includes
PetClinic's code and its dependencies. The other file, suffixed `.original`, is just PetClinic's code
without its dependencies. The result is that our code size is `372KB` and the dependencies' `43MB`. 

## Docker image's size

Build PetClinic's Docker image:

```
    ./mvnw dockerfile:build
```

Measure the image size:

```
    docker image ls | grep spring-petclinic
```

Result:

```
org.springframework.samples/spring-petclinic   latest              83de9c37617a        43 seconds ago      147MB
```

We can see that size of the artifact has increased from `43MB` to `147MB`. This is mainly because the 
Docker image includes the JDK and Linux images. Run this command to check it:

```
    docker image history org.springframework.samples/spring-petclinic
```

The result shows the different layers added to the Docker image:

```
Inigos-MacBook-Pro:spring-petclinic inigo$ docker image history org.springframework.samples/spring-petclinic
IMAGE               CREATED              CREATED BY                                      SIZE                COMMENT
83de9c37617a        About a minute ago   /bin/sh -c #(nop)  CMD ["/bin/sh" "-c" "/usr…   0B                  
45d0d553fc08        About a minute ago   /bin/sh -c #(nop)  EXPOSE 8080                  0B                  
90e1922c6a70        About a minute ago   /bin/sh -c #(nop) COPY file:71594a32c3e9592c…   44.6MB              
0aca9ece378a        46 hours ago         /bin/sh -c #(nop)  ARG JAR_FILE                 0B                  
a3fd1d8db4ba        46 hours ago         /bin/sh -c #(nop)  VOLUME [/tmp]                0B                  
97bc1352afde        6 weeks ago          /bin/sh -c set -x  && apk add --no-cache   o…   98.2MB              
<missing>           6 weeks ago          /bin/sh -c #(nop)  ENV JAVA_ALPINE_VERSION=8…   0B                  
<missing>           6 weeks ago          /bin/sh -c #(nop)  ENV JAVA_VERSION=8u181       0B                  
<missing>           2 months ago         /bin/sh -c #(nop)  ENV PATH=/usr/local/sbin:…   0B                  
<missing>           2 months ago         /bin/sh -c #(nop)  ENV JAVA_HOME=/usr/lib/jv…   0B                  
<missing>           2 months ago         /bin/sh -c {   echo '#!/bin/sh';   echo 'set…   87B                 
<missing>           2 months ago         /bin/sh -c #(nop)  ENV LANG=C.UTF-8             0B                  
<missing>           2 months ago         /bin/sh -c #(nop)  CMD ["/bin/sh"]              0B                  
<missing>           2 months ago         /bin/sh -c #(nop) ADD file:25c10b1d1b41d46a1…   4.41MB    
```

The `4.41MB` image is the Alpine Linux image and the `98.2MB` image is the JDK8 image (it 
includes the previous Alpine Linux image as well). The sum of all them results in an image of
`140MB` which includes Linux OS, JDK8, PetClinic's code and dependencies' jar.  

> Different Linux image comparison at https://github.com/gliderlabs/docker-alpine#why 

# Memory usage

## Spring Boot artifact's memory usage

Run PetClinic application with this command:

```
java -jar target/spring-petclinic-2.1.0.BUILD-SNAPSHOT.jar
```

Open `JConsole` (or other profiler such as YourKit) and measure the heap after executing Garbage Collector (GC). The 
result is this:

![jconsole-result](jconsole/result.png)

With no load the application's heap consumption is around `42MB` . However, the memory consumption is bigger than just the
heap, so let's measure it using ``ps`` command:

```
Inigos-MacBook-Pro:spring-boot-docker-size inigo$ ps aux 7241
USER    PID  %CPU %MEM      VSZ    RSS   TT  STAT STARTED      TIME COMMAND
inigo  7241   0.1  3.5 10159824 590672 s000  S+   10:04PM   0:36.61 /usr/bin/java -jar target/spring-petclinic-2.1.0.BUILD-SNAPSHOT.jar
```

We can see that PetClinic's process actually is using almost `60MB` of memory.  

## Docker image's memory usage

Run a PetClinic container with this command:

```
docker run org.springframework.samples/spring-petclinic
```

Executing ``docker stats`` we can find out how much memory is using the container with no load:

```
CONTAINER ID        NAME                CPU %               MEM USAGE / LIMIT     MEM %               NET I/O             BLOCK I/O           PIDS
083735c6f8da        goofy_chatelet      0.31%               507.8MiB / 5.818GiB   8.52%               788B / 0B           0B / 0B             33
```

So, the container uses ``507MB`` of memory. 

> Interesting resource about measuring Spring Boot: https://spring.io/blog/2015/12/10/spring-boot-memory-performance

# Summary

| Feature                                           | Spring Boot 2.0.0 | Spring Boot 2.1.1 |
| ------------------------------------------------- | ----------------- | ----------------- |
| Spring Boot App disk usage                        | 37MB              | 43M               |
| Spring Boot App disk usage (without dependencies) | 372KB             | 372KB             |
| Docker Container disk usage                       | 140MB             | 147MB             |
| Spring Boot App heap consumption                  | 60MB              | 42MB              |
| Spring Boot App memory usage                      | 80MB              | 60MB              |
| Docker Container memory usage                     | 512MB             | 507MB             |


# Credits

Original PetClinic by https://www.spring.io

Docker configuration by https://www.arima.eu

![ARIMA Software Design](https://arima.eu/arima-claim.png)
