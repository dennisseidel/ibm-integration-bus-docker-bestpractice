This is no official IBM image, but based on my experiences and opinions.

# The IBM Integration Bus Docker - Runtime *ALPHA*

This repository includes docker images for IBM Integration Bus according to [container best practices](http://developers.redhat.com/blog/2016/02/24/10-things-to-avoid-in-docker-containers/) 
from which the developer can select as the foundation for his RuntimeLayer image ([example](https://github.com/dennisseidel/iib-bestpractice-applications-template)):
- `iib-10.0.0.7`: Creates an Ubuntu 14.04 image with IIB in version `10.0.0.7`  
- `iib-10.0.0.7-mqclient`: Adds MQClient 9 to the `iib-10.0.0.7` image

The images allow for alot of configuration just through environment variables instead of commands inside the container. Please see the following list for the currently supported features.
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

#### The PKI Infrastructure can be configured as follows by setting the following env variables the iib configuration will be done by the base image automatically if both variables are available and the keystore:
- `IIB_KEYSTOREPW`: the keystore password, can be set as an environment variable or in the `pw.sh` file mounted under `/secret/pw.sh`.
- `IIB_TRUSTSTOREPW`: the truststore password, can be set as an environment variable or in the `pw.sh` file mounted under `/secret/pw.sh`.
- Add a keystore and truststore under `/secret/keystore.jks` and `/secret/truststore.jks` to enable HTTPS or SSL MQ.

#### ODBC can be configured by: 
- Mounting your odbc.ini into `/var/mqsi/odbc.ini`
- Set Environment variable `ODBCINI`: to the path of the odbc.ini. Which must be currently `/secret/odbc.ini`.
- Create and copy/mount a custome configuration file that sets your security identity in: `/secret/customconfig.sh` this file is automatically pick up by the container and executed. You should include a command like: `mqsisetdbparms MYNODE -n odbc::ORACLEDB -u BASE_USER -p secretpassword`. `ORACLEDB` is the name of the resource in the odbc.ini file I have give (you can choose your own), `BASE_USER_ANFW` is the username, `secretpassword` is the place to put your password.
- Set a fixed keyAlias for the ServerCertificate by setting the Env variable `IIB_SERVER_CERT_ALIAS`

#### Exposed Ports:
    - 4414: Port of the IIB Admin WebUi and for remote debugging in IBM Integration Bus Toolkit
    - 7800: Port of the HTTP Listener

## Usage Process
If you have the need for a new image or want to modify one of the existing runtime images:

1. Update or add a Version Number in the `env` file and run it `. ./env`
2. Create a new folder with a new definition of a runtime layer image.
3. Add the image to the `docker-compose` file according to the other images.
4. Build the image with `docker-compose build` (e.g. `docker-compose build iib-mqclient`) test it locally and if ok then check into git repo.
5. Push the image into the container repository of your choice for applicaiton developers to use.

## Experiences:
- Deploying (stage specific) artefacts (bar files) at run time by getting it from a config server. Has the disadvantage that this requires multiple files for each stage. Leading to the problem that you might forget to update the artefact on all stages. IMMUTABILITY VIOLATED.
- Mounting the deloyment artefacts from another container. In container plattforms like OpenShift or Kubernetes there is no possibility to specify dependencies between containers, this makes it complex (not impossible) to make it work and maintain.
