# Easy setup for Twitter as Kafka consumer with Apache Nifi

One tipical BigData usecase is reading Twitter informations, and analyze them.
Twitter is deliver us an API, what we should access. Some years ago this was a bit complex part of the solutions. Now, with the help of Apache Nifi it is getting more simple. The only task what we have to do is setup a Kafka (with zookeeper) and a Nifi in a docker container, or local on a developer machine, or on server.

My article is about the setup of the environment and the configuration of the Kafka producer with Apache Nifi.

## The environment

### The Dockerfile

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


And now let see it line by line: 

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
Build a shell file, which contains all the execute commands what are needed to execute Kafka and Nifi parallel.

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

### Start using Nifi

After the execution of the container we have to wait about 1-2 Minutes, and we can open a browser and start using Nifi on http://localhost:8080/nifi address.

Now we have to add two processors:
* GetTwitter
* PublishKafka_0_10

Let join them from GetTwitter to PublisKafka.

### Setup GetTwitter
Now click with right mouse button on GetTwitter and open the configuration window from GetTwitter. 
Here we have to fill out the following attributes:

* Consumer Key
* Consumer Secret Key
* AK
* AKS

Click on Apply.

### Setup PublishKafka
Now click with right mouse button on PublishKafka and open the configuration window from PublishKafka. 
Here we have to fill out the following attributes:

* topic

Here fill out with the KAfka topic, which is _twitter_

Click on Apply.

Now we are ready. Click on Dashboard and execute the Process group with play button. 

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



















