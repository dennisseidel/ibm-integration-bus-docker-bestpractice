# The IBM Integration Bus Docker Framework - RuntimeLayer *ALPHA*

This repository includes a docker image framework for IBM Integration Bus according to [container best practices](http://developers.redhat.com/blog/2016/02/24/10-things-to-avoid-in-docker-containers/).

The framework consists of two Layers:
  - [RuntimeLayer](https://github.com/dennisseidel/iib-bestpractice-runtimes): This repository includes the different images that are prepared and form the foundation for the the AppLayer.
  - [AppLayer](https://github.com/dennisseidel/iib-bestpractice-applications-template): This repository include a template for a developer to develop his own immutable image for his applications.

This repository includes the source code for the following RuntimeLayer images from which the developer can select as the foundation for his AppLayer image:
- `iib-10.0.0.6`: Creates an Ubuntu 14.04 image with IIB in version `10.0.0.6`
- `iib-10.0.0.6-mqclient`: Adds MQClient 9 to the `iib-10.0.0.6` image

## Image Parameters:

### iib-10.0.0.6-mqclient / iib-10.0.0.6

- Default config of IIB:
  - nodename: MYNODE
  - integrationservername: default
  - two users for the webadminui, also to be used when connecting from IIB Toolkit to the Integrationnode:
    - admin:
      - can read, write, execute
      - password must be set by definining it in the IIB_ADMINPW variable
    - observer:
      - can read only
      - password must be set by definining it in the IIB_OBSERVERPW variable
- Environment variables:
    - IIB_TRACEMODE: this can be set to `on` or `off` to en/disable trace nodes.
    - IIB_LICENSE: this must be set to `accept` to indicate that you accepted the IBM License Agreement
    - IIB_SKIPDEPLOY: Skip deployment of IIB applications, useful in development
    - IIB_GLOBALCACHE: if set to `internal` the global cache on IIB is just enabled. If set to `external` the connection to an external IBM Extreme Scale is configured. This requires the following environment variables to be set:
      - IIB_GC_USER: username to connect to IBM Extreme Scale
      - IIB_GC_PASSWD: password to connect to IBM Extreme Scale
      - IIB_GC_CATALOGENDPOINT: catalogendpoint to connect to IBM Extreme Scale
      - IIB_GC_GRIDNAME gridname to connect to IBM Extreme Scale
		The PKI Infrastructure can be configured as follows by setting the following env variables the iib configuration will be done by the base image automatically if both variables are available and the keystore:
			- `IIB_KEYSTOREPW`: the keystore password, can be set as an environment variable or in the `pw.sh` file mounted under `/secret/pw.sh`.
			- `IIB_TRUSTSTOREPW`: the truststore password, can be set as an environment variable or in the `pw.sh` file mounted under `/secret/pw.sh`.
			- Add a keystore and truststore under `/secret/keystore.jks` and `/secret/truststore.jks` to enable HTTPS or SSL MQ.
- Exposed Ports:
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
