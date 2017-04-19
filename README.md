This is no official IBM image, but based on my experiences and opinions.

# The IBM Integration Bus Docker - Runtime *ALPHA*

This repository includes docker images for IBM Integration Bus according to [container best practices](http://developers.redhat.com/blog/2016/02/24/10-things-to-avoid-in-docker-containers/) 
from which the developer can select as the foundation for his RuntimeLayer image ([example](https://github.com/dennisseidel/iib-bestpractice-applications-template)):
- `iib-10.0.0.8`: Creates an Ubuntu 14.04 image with IIB in version `10.0.0.8`  
- `iib-10.0.0.8-mqclient`: Adds MQClient 9 to the `iib-10.0.0.8` image
- `iib-10.0.0.8-mqserver`: Adds an MQServer V9 to the `iib-10.0.0.8` image => NOT YET WORKING!

The images allow for the configuration just through environment variables instead of commands inside the container. Please see the following list for the currently supported features.
Feedback is always welcome so if you missing something open a issue. Thank you.

## Image Parameters:

### iib-10.0.0.7-mqclient / iib-10.0.0.7

#### Default config of IIB:
  - nodename: MYNODE
  - integrationservername: default
  - two users for the webadminui, also to be used when connecting from IIB Toolkit to the Integrationnode:
    - admin:
      - can read, write, execute
      - password must be set by definining it in the IIB_ADMINPW variable
    - observer:
      - can read only
      - password must be set by definining it in the IIB_OBSERVERPW variable

#### Environment variables:
- IIB_TRACEMODE: this can be set to `on` or `off` to en/disable trace nodes.
- IIB_DEBUGPORT: this can be set to any port e.g. `9999`. If this is set the debug port is automatically set on start up. Don't do this in production. Further you need to expose this port in your image.  
- IIB_LICENSE: this must be set to `accept` to indicate that you accepted the IBM License Agreement
- IIB_SKIPDEPLOY: Skip deployment of IIB applications, useful in development
- IIB_GLOBALCACHE: if set to `internal` the global cache on IIB is just enabled. If set to `external` the connection to an external IBM Extreme Scale is configured. This requires the following environment variables to be set:
      - IIB_GC_USER: username to connect to IBM Extreme Scale
      - IIB_GC_PASSWD: password to connect to IBM Extreme Scale
      - IIB_GC_CATALOGENDPOINT: catalogendpoint to connect to IBM Extreme Scale
      - IIB_GC_GRIDNAME gridname to connect to IBM Extreme Scale
- Set a fixed keyAlias for the ServerCertificate by setting the Env variable `IIB_SERVER_CERT_ALIAS`. This should be the alias of the server certificate e.g. iib_server_cert, find this on in your certificate. 

#### The PKI Infrastructure can be configured as follows by setting the following env variables the iib configuration will be done by the base image automatically if both variables are available and the keystore:
- `IIB_KEYSTOREPW`: the keystore password, can be set as an environment variable or in the `pw.sh` file mounted under `/secret/pw.sh`.
- `IIB_TRUSTSTOREPW`: the truststore password, can be set as an environment variable or in the `pw.sh` file mounted under `/secret/pw.sh`.
- Add a keystore and truststore under `/secret/keystore.jks` and `/secret/truststore.jks` to enable HTTPS or SSL MQ.

#### ODBC can be configured by: 
- Mounting your odbc.ini into `/var/mqsi/odbc.ini`
- Set Environment variable `ODBCINI`: to the path of the odbc.ini. Which must be currently `/secret/odbc.ini`.
- Create and copy/mount a custome configuration file that sets your security identity in: `/secret/customconfig.sh` this file is automatically pick up by the container and executed. You should include a command like: `mqsisetdbparms MYNODE -n odbc::ORACLEDB -u BASE_USER -p secretpassword`. `ORACLEDB` is the name of the resource in the odbc.ini file I have give (you can choose your own), `BASE_USER_ANFW` is the username, `secretpassword` is the place to put your password.

#### Exposed Ports:
    - 4414: Port of the IIB Admin WebUi and for remote debugging in IBM Integration Bus Toolkit
    - 7800: Port of the HTTP Listener (HTTP)
    - 7843: Port for the HTTP Listner (HTTPS) 

## How to use 

1. Create your own Dockerfile with e.g. `FROM dennisseidel/iib-bestpractice-runtimes:${tag}` or any other tag shown above.

```
FROM dennisseidel/iib-bestpractice-runtimes:10.0.0.7-mqclient

MAINTAINER YourName your@mail.com
```

2. Define in the Dockerfile the artefacts you want to copy into the image, if you want to change them at runtime you can just mount other files over them: 

```
# MANDATORY: BAR Files
# Copy all application bar files into the docker container to /iibProjects/
# from where they are deployed at runtime
COPY workspace/BARfiles/app.bar /iibProjects/

# OPTIONALLY: Overwrite Files
# Copy all properties/overwrite files to /iibProperties/. They are applied to
# the bar file with the same name (app.properties applied to app.bar)
# These files can be "overwritten" by putting the properties file into a mountpoint
# or a configmap (kubernetes/openshift specific)
COPY config/app.properties /iibProperties/

# OPTIONALLY: Custom Config Hook
# Add a file called customconfig.sh with mqsi commands ran at runtime before the
# bar file is deployed.
# This file can be also be stage specific mounted into the image.
#COPY config/customconfig.sh /usr/local/bin/customconfig.sh

# MANDATORY: Secrets (Passwords / keystore / truststore
# Password need to be mounted into the location /secret as a pw.sh (see example)
# this allow you to set export environment variables for on run when the container start
# those passwords are not visable afterwards.
# The keystore needs to be mounted into /secret as keystore.jks
# The trust store needs to be mounted into /secret as truststore.jks
COPY config/secret/ /secret/

# OPTIONALLY: ODBC.ini for ODBC support in ESQL
# this file can on other stages be comming from a secret or a config map depending on the
# information that comes from this file.
# COPY config/odbc.ini /secret

# OPTIONAL: copy files that can be served by a mock service and read with a file input node
COPY workspace/mocks/ /mock/data
```
3. Either create docker-compose.yaml file or build and start the docker container based on your created Dockerfile. [see Docker Documentation](https://docs.docker.com/get-started/part2/#build-the-app). 

```
# build the runtime image
docker build -t iib-app-image .
# start the runtime image
docker run -p 7800:7800 -p 7843:7843 -p 4414:4414 iib-app-image
```

## How to modify the image. 
2. Create a new folder with a new definition of a runtime layer image.
3. Add the image to the `docker-compose` file according to the other images.
4. Build the image with `docker-compose build` (e.g. `docker-compose build iib-mqclient`) test it locally and if ok then check into git repo.
5. Push the image into the container repository of your choice for applicaiton developers to use.

## Experiences:
- Deploying (stage specific) artefacts (bar files) at run time by getting it from a config server. Has the disadvantage that this requires multiple files for each stage. Leading to the problem that you might forget to update the artefact on all stages. IMMUTABILITY VIOLATED.
- Mounting the deloyment artefacts from another container. In container plattforms like OpenShift or Kubernetes there is no possibility to specify dependencies between containers, this makes it complex (not impossible) to make it work and maintain.
