# bigdata2go
Lightweight, flexible BigData streaming application 

## About

This application is a reference project. The main purpose is to deliver a flexible development and presentation framework, which contains the all the arefacts from data source to presentation component.

This tutorial show the steps of the environment. 

The first part is about to setup the infrastructure. It is based on docker containers. To make it more flexible, every component, software is installed on own container. The program code, the development is not on containers, it is in github. When the container starts, the code will be downloaded and executed. 

To execute the environment docker compose utility is used. It helps to execute and work parallel with more docker containers. The hierarchy and the configuration has to be configured in a docker-compose.yml file. 

The second part of the tutorial is the data ingestion part where the data is loaded from Twitter to Kafka. Here the Apache Nifi is used to connect to Twitter and download the Sample Stream as JSON text into Kafka. 

The third part is a Spark Streaming development. With Spark Streaming the JSON Strings are ingested and parsed from Kafka and analyzed by hashtags.  

The fourth part is the web application, it is a simple node.js express application which shows the most used Twitter Hashtags from the stream. 

## 1. The environment

The infrastructure contains currently four containers. Currently, the web application is on the same container as cassandra. 

The containers are:
- zookeeper : trivadisbds/zookeeper image from Trivadis
- kafka : gszecsenyi/kafka image by me
- nifi : gszecsenyi/nifi image by me
- cassandra : gszecsenyi/cassandra - offical cassandra image with additional linux softwares installed

### 1.1 The main components

#### Zookeeper

Zookeeper is a tool, which is for... It was developed by ... The communication works. .. 

#### Kafka 

Kafka 

#### Nifi

#### Spark (with sbt)

#### Cassandra

#### Web UI

The application, which shows the informations is a Node.js webapplication. On Node.js the Express framework is running. The datastax cassandra driver support the communication between the java script engine and Cassandra

### 1.2 Docker compose

#### The docker compose file

#### Docker Images

### 2. Streaming Twitter to Kafka with Apache Nifi

A very common BigData use-case is the collection and processing of Twitter tweets. It can be done on different ways. The Twitter stream can be stored on HDFS or another local drive or immediately processed with a streaming supported engine as Storm, Spark or Flink. In both cases the first step is that the tweets will be collected in a Kafka queue.

Kafka is a horizontally scalable, fault-tolerant distributed publish-subscribe messaging platform. It is written in Scala and was originally developed by LinkedIn. Suitable for both offline and online message consumption. Kafka maintains feeds of messages in topics. 
Data are written into optics by producers and consumers read from there. Since Kafka is a distributed system, topics are partitioned and replicated across multiple nodes. In this case only one instance with one replication factor and one partition will be used. 

Twitter delivers API, what should be accessed. Some years ago this was a bit complex part of the solutions, now, with the help of Apache Nifi it is getting simpler. The only task that has to be done is, to setup a Kafka (with zookeeper) and a Nifi in a docker container or on a server and configure Nifi with the Twitter access attributes.

Apache Nifi is an integration and dataflow automation tool with a user-friendly drag-and-drop graphical user interface, that allows a user to send, receive, route, transform, and sort data, as needed, in an automated and configurable way. 

Nifi has a built-in REST api, which helps to control the Nifi processes. The REST communication will be happen with curl. In some cases, the answer is a JSON string, which will be parsed with jq software. https://stedolan.github.io/jq/ In this application this REST api add the template, instance the template and start the processes within Nifi, automatically.

A Process group as template is prepared,  which contains a GetTwitter processor and a PutKafka0_10, linked together. On starting of the application, this Process Group template will be instanced, uploaded, and the processes started.

Here is how the Process Group template was developed

#### 2.1 Preparing process group template for Twitter 2 Kafka stream

The Nifi can be opened and used in a browser on the http://localhost:8080/nifi address.

##### 2.1.1 Start developing the process group
![alt text](https://cloud.githubusercontent.com/assets/363452/26026243/200e02fc-37f8-11e7-81ad-d55da300a69f.png "Start using Nifi")

At this point two processor has to be added:

* GetTwitter
* PublishKafka\_0\_10

They can be joined from GetTwitter to PublishKafka_0_10 Processor.

![alt text](https://cloud.githubusercontent.com/assets/363452/26026240/1fedc12c-37f8-11e7-9894-b3eac4434419.png "Start using Nifi")

##### 2.1.2 Setup GetTwitter
The configuration window can be accessed by right mouse click on GetTwitter. The following attributes has to be filled:

* Consumer Key
* Consumer Secret 
* Access Token
* Access Token Secret

![alt text](https://cloud.githubusercontent.com/assets/363452/26026238/1fcd4b68-37f8-11e7-9a63-25fbbf00f358.png "Setup GetTwitter")


Click on Apply.

##### 2.1.3 Setup PublishKafka_0_10
Open the configuration window from PublishKafka by right click on PulishKafka_0_10. Fill the attribute:

* topic

Here fill out with the Kafka topic, which is _twitter_ 

![alt text](https://cloud.githubusercontent.com/assets/363452/26026237/1fcc1b94-37f8-11e7-813e-ab93a1c26905.png "Setup PublishKafka_0_10")

After clicking the ‘Apply’ button the task is done.

##### 2.1.4 Executing the dataflow

The Process group can be executed with the play button on the Dashboard.

![alt text](https://cloud.githubusercontent.com/assets/363452/26026235/1f89b146-37f8-11e7-96e8-a9be8dcd452a.png "Executing the dataflow")

##### 2.1.5 Export the template

#### 2.2 Scripts for starting the environment

Uploading the template the following script is used:
```sh
# Upload the template
curl -F template=@Twitter2Kafka_Process_group.xml \ 
    -X POST http://172.17.0.4:8080/nifi-api/process-groups/root/templates/upload
```

When the template is uploaded, is should be instanced with the following script:
```sh
# Instance the template with id
curl -H "Content-Type: application/json" -X POST \
    -d '{"originX": 50.0, "originY": 50.0, "templateId": '$(curl -X GET http://172.17.0.4:8080/nifi-api/flow/templates | jq .templates[0].id)' }' \
    http://172.17.0.4:8080/nifi-api/process-groups/root/template-instance
```

As it's visible, it contains two curl calls. The inner curl call is to get the uploaded template id. The outer call is for the instancing the first template ( there is only one template uploaded at this time ). After the instancing the template appear on the Nifi dashboard. The position of the template is also the parameter of the call, 50pixels from the top and 50 pixels from the left side. 

In this case, the template contains all the informations what is necessary to execute the Processes. So the next step is to execute those processes.

The following statement will do the execution for one of the processors
```sh
url="http://172.17.0.4:8080/nifi-api/processors/$(curl -X GET http://172.17.0.4:8080/nifi-api/process-groups/root/processors | jq .processors[0].id | tr -d '"')"
version=$(curl -X GET http://172.17.0.4:8080/nifi-api/process-groups/root/processors | jq .processors[0].revision.version | tr -d '"')
c_id=$(curl -X GET http://172.17.0.4:8080/nifi-api/process-groups/root/processors | jq .processors[0].id)
curl $url -X PUT -H 'Content-Type: application/json' -H 'Accept: application/json, text/javascript, */*; q=0.01' --data-binary '{"revision":{"clientId":"'$client_id'","version":'$version'},"component":{"id":'$c_id',"state":"RUNNING"}}'
```

The first line defines the url. This variable define also contains a curl call to get the processor id for the variable. Then the current version of state has to be defined for Nifi. The third lines get the processor-id again, but with double-quotes. The fourth line contains the main call, where the processor state is defined (RUNNING) with some mandatory parameters as client_id and version. 

The same query is for the other processor too. 
```sh
url="http://172.17.0.4:8080/nifi-api/processors/$(curl -X GET http://172.17.0.4:8080/nifi-api/process-groups/root/processors | jq .processors[1].id | tr -d '"')"
version=$(curl -X GET http://172.17.0.4:8080/nifi-api/process-groups/root/processors | jq .processors[1].revision.version | tr -d '"')
c_id=$(curl -X GET http://172.17.0.4:8080/nifi-api/process-groups/root/processors | jq .processors[1].id)
curl $url -X PUT -H 'Content-Type: application/json' -H 'Accept: application/json, text/javascript, */*; q=0.01' --data-binary '{"revision":{"clientId":"'$client_id'","version":'$version'},"component":{"id":'$c_id',"state":"RUNNING"}}'
```