# The IBM Integration Bus Docker Framework - RuntimeLayer (immuatable and only pulled by a developer)

This repository includes a docker image framework for IBM Integration Bus according to [container best practices](http://developers.redhat.com/blog/2016/02/24/10-things-to-avoid-in-docker-containers/).

The Framework exists of two Layers:
  - [RuntimeLayer](https://github.com/dennisseidel/iib-bestpractice-runtimes): This repository includes the different Runtime Images that are prepared and are the foundation for the the AppLayer the developer is only concerted with the AppLayer. This images should not change often.
  - [AppLayer](https://github.com/dennisseidel/iib-bestpractice-applications-template): This repository include a template for a developer to develop his own immutable image for his applications.

This repository include the source code for the following RuntimeLayer Images from which the developer can select as the foundation for his AppLayer image:
- `./mqclient-9.0.0/`: This build a image that contains an Ubuntu 14.04 and an mqclient with MQ Version 9.0.0.
- `./iib-10.0.0.6-mqclient/`: This builds a image that bases on the image `mqclient-9.0.0` with an IIB in Version `10.0.0.6`.
- `./iib-10.0.0.6/`: This builds Ubuntu 14.04 image with an IIB in Version `10.0.0.6`.

You can add more runtime images and if you have a configuration that should aways be don't then this can be added to these Images with the RuntimeLayer.

## Image Parameters:

### iib-10.0.0.6-mqclient / iib-10.0.0.6

- Standardconfig of IIB:
  - nodename: MYNODE
  - integrationservername: default
  - two user for the webadminui also to be used when connection from IIB Toolkit to the Integrationnode:
    - admin:
      - can read, write, execute
      - password must be set through the pw.sh with the defintion of IIBADMINPW variable
    - observer:
      - can read only
      - password must be set through the pw.sh with the defintion of IIBOBSERVERPW variable
- Environment variables:
    - IIB_TRACEMODE: this can be set `on` or `off` and en/disables trace nodes.
    - IIB_LICENSE: this must be set to `accept` indicated that you accepted the IBM License Agreement
    - IIB_GLOBALCACHE: if set to `internal` the global cache on IIB is just enabled. If set to `external` the connection to an external IBM Extreme Scale is configured this requires the following environment variables to be set:
      - IIB_GC_USER: username to connect to IBM Extreme Scale
      - IIB_GC_PASSWD: password to connect to IBM Extreme Scale
      - IIB_GC_CATALOGENDPOINT: catalogendpoint to connect to IBM Extreme Scale
      - IIB_GC_GRIDNAME gridname to connect to IBM Extreme Scale
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
