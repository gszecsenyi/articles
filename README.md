# Twitter Stream to Kafka with Apache Nifi

A very common BigData usecase is when Twitter tweets are collected and analysed. This has more forms. The Twitter stream will be stored on HDFS or another local drive or will be analysed or immediately processed with a streaming supported engine as Storm, Spark or Flink. In both case the first step is that the tweets will be collected in a Kafka queue. 
Kafka is a horizontall scalable, fault-tolerant distributed publish-subscribe messaging platform. Kafka is written in Scala and was originally developed by LinkedIn. It is suitable for both offline and online message consumption. 

Twitter is deliver us an API, what we should access. Some years ago this was a bit complex part of the solutions. Now, with the help of Apache Nifi it is getting more simple. The only task what we have to do is setup a Kafka (with zookeeper) and a Nifi in a docker container, or local on a developer machine, or on server.

My article is about the setup of the environment and the configuration of the Kafka producer with Apache Nifi.

## Start using the environment

### Preparations

#### Register a twitter account and create application for authentication informations

We have to register first a Twitter account on http://twitter.com, and register an application on http://apps.twitter.com URL. 

After the registration we have to create an application key on the same site, and now we have all the information, what we need from Twitter.

* Consumer Key
* Consumer Secret Key
* AK
* AKS

### Create and execute the container 

Now we start the container. When the docker image is not available on the local host, then the docker client will once download the image to the local computer. It is about 1GB.

```
docker run -i -d --name twitter2kafka_container -p 8080:8080 -p 2181:2181 -p 9092:9092 -t gszecsenyi/twitter2kafka 
```

As we see, there is three port assignment. The first port is the port of the Apache Nifi client. We can access Apache Nifi with our Internet Browser. The second and the third port is for zookeeper and Kafka. With the third port we will access our Kafka queue and we can download the messages with a consumer. ( For example with our Spark program). 

### Create Kafka topic

Open a new shell and execute the following command to login into your running container:

```
docker exec -it twitter2kafka_container /bin/bash
```
Now we create a twitter topic within Kafka
```
/opt/kafka/bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic twitter
```

![alt text](https://cloud.githubusercontent.com/assets/363452/26026236/1fac5eda-37f8-11e7-99dd-4dbd8877c65d.png "Create Kafka topic")

### Start using Nifi

After the execution of the container we have to wait about 1-2 Minutes, and we can open a browser and start using Nifi on http://localhost:8080/nifi address.

![alt text](https://cloud.githubusercontent.com/assets/363452/26026243/200e02fc-37f8-11e7-81ad-d55da300a69f.png "Start using Nifi")

Now we have to add two processors:
* GetTwitter
* PublishKafka_0_10

Let join them from GetTwitter to PublishKafka_0_10.

![alt text](https://cloud.githubusercontent.com/assets/363452/26026240/1fedc12c-37f8-11e7-9894-b3eac4434419.png "Start using Nifi")

### Setup GetTwitter
Now click with right mouse button on GetTwitter and open the configuration window from GetTwitter. 
Here we have to fill out the following attributes:

* Consumer Key
* Consumer Secret Key
* AK
* AKS

![alt text](https://cloud.githubusercontent.com/assets/363452/26026238/1fcd4b68-37f8-11e7-9a63-25fbbf00f358.png "Setup GetTwitter")


Click on Apply.

### Setup PublishKafka_0_10
Now click with right mouse button on PublishKafka_0_10 and open the configuration window from PublishKafka. 
Here we have to fill out the following attributes:

* topic

Here fill out with the KAfka topic, which is _twitter_

![alt text](https://cloud.githubusercontent.com/assets/363452/26026237/1fcc1b94-37f8-11e7-813e-ab93a1c26905.png "Setup PublishKafka_0_10")

Click on Apply.

### Executing the dataflow

Now we are ready. Click on Dashboard and execute the Process group with play button. 

![alt text](https://cloud.githubusercontent.com/assets/363452/26026235/1f89b146-37f8-11e7-96e8-a9be8dcd452a.png "Executing the dataflow")

### Setup a consumer for testing our dataflow. 

Open a new shell window and execute the following commands
```
docker exec -it twitter2kafka_container /bin/bash
```
Now we start a console consumer to check the incoming dataflow in Kafka
```
/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic twitter
```

We will see in JSON format the twitter data stream

![alt text](https://cloud.githubusercontent.com/assets/363452/26026242/200afdf0-37f8-11e7-96b4-d4b8210f5d3e.png "Setup a consumer for testing our dataflow.")


### Delete the docker container
```
docker rm -f twitter2kafka_container
```

## The Dockerfile

```docker
# based on input by: Guido Schmutz <@gschmutz>

FROM            trivadisbds/base

MAINTAINER      Gergely Szecsenyi <gergely.szecsenyi@trivadis.com>

# Define the environment variables for Kafka and Nifi source files, installation homes and versions
ENV             NIFI_DIST_MIRROR             http://mirror.cc.columbia.edu/pub/software/apache/nifi
ENV             NIFI_HOME                    /opt/nifi
ENV             NIFI_VERSION                 1.2.0

ENV             KAFKA_DIST_MIRROR             http://tux.rainside.sk/apache/kafka
ENV             KAFKA_HOME                    /opt/kafka
ENV             KAFKA_VERSION                 0.10.1.0
ENV             SCALA_VERSION                 2.11

# Install necessary packages, create target directory, download and extract, and update the banner to let people know what version they are using
RUN             mkdir -p ${NIFI_HOME} && \
                curl ${NIFI_DIST_MIRROR}/${NIFI_VERSION}/nifi-${NIFI_VERSION}-bin.tar.gz | tar xvz -C ${NIFI_HOME} --strip-components=1 && \
                sed -i -e "s|^nifi.ui.banner.text=.*$|nifi.ui.banner.text=Trivadisbds Docker NiFi ${NIFI_VERSION}|" ${NIFI_HOME}/conf/nifi.properties

RUN             wget -c ${KAFKA_DIST_MIRROR}/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
                tar -xzvf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
                mv kafka_${SCALA_VERSION}-${KAFKA_VERSION} /opt && \
                ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/ ${KAFKA_HOME}

RUN             echo '#!/bin/bash' > /usr/bin/start-kafka.sh && \
                echo "cd ${KAFKA_HOME}" >> /usr/bin/start-kafka.sh && \
                echo "bin/zookeeper-server-start.sh config/zookeeper.properties & > ~/output.log" >> /usr/bin/start-kafka.sh && \
                echo "bin/kafka-server-start.sh config/server.properties & > ~/output.log" >> /usr/bin/start-kafka.sh && \
                echo "${NIFI_HOME}/bin/nifi.sh run & > ~/output.log" >> /usr/bin/start-kafka.sh && \
                echo "tail -f ~/output.log" >> /usr/bin/start-kafka.sh  && \
                chmod +x /usr/bin/start-kafka.sh

# Expose web port
EXPOSE          80 8080 2181 9092

CMD ["start-kafka.sh"]
```

### And now let see the Dockerfile step by step: 

```docker
FROM            trivadisbds/base
```
The parent image is the trivadisbds/base image, which is a RedHat image whith Java installation

```docker
ENV             NIFI_DIST_MIRROR             http://mirror.cc.columbia.edu/pub/software/apache/nifi
ENV             NIFI_HOME                    /opt/nifi
ENV             NIFI_VERSION                 1.2.0

ENV             KAFKA_DIST_MIRROR             http://tux.rainside.sk/apache/kafka
ENV             KAFKA_HOME                    /opt/kafka
ENV             KAFKA_VERSION                 0.10.1.0
ENV             SCALA_VERSION                 2.11
```

We set environment variables for the container, which (AP:the environment varialbes) contains the URL, version and home for products. With this solution the Dockerfile is easier maintenable. 

```docker
RUN             mkdir -p ${NIFI_HOME} && \
                curl ${NIFI_DIST_MIRROR}/${NIFI_VERSION}/nifi-${NIFI_VERSION}-bin.tar.gz | tar xvz -C ${NIFI_HOME} --strip-components=1 && \
                sed -i -e "s|^nifi.ui.banner.text=.*$|nifi.ui.banner.text=Trivadisbds Docker NiFi ${NIFI_VERSION}|" ${NIFI_HOME}/conf/nifi.properties

```
Download and extracting the Apache Nifi software

```docker
RUN             wget -c ${KAFKA_DIST_MIRROR}/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
                tar -xzvf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
                mv kafka_${SCALA_VERSION}-${KAFKA_VERSION} /opt && \
                ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/ ${KAFKA_HOME}
```
Donwloading and extracting the Apache Kafka software

```docker
RUN             echo '#!/bin/bash' > /usr/bin/start-kafka.sh && \
                echo "cd ${KAFKA_HOME}" >> /usr/bin/start-kafka.sh && \
                echo "bin/zookeeper-server-start.sh config/zookeeper.properties & > ~/output.log" >> /usr/bin/start-kafka.sh && \
                echo "bin/kafka-server-start.sh config/server.properties & > ~/output.log" >> /usr/bin/start-kafka.sh && \
                echo "${NIFI_HOME}/bin/nifi.sh run & > ~/output.log" >> /usr/bin/start-kafka.sh && \
                echo "tail -f ~/output.log" >> /usr/bin/start-kafka.sh  && \
                chmod +x /usr/bin/start-kafka.sh
```
This build a shell file, which contains all the execute commands what are needed to execute Kafka and Nifi parallel.
