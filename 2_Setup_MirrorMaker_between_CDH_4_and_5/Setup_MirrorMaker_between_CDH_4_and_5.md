# Setup MirrorMaker between CDH 4 and CDH 5.

## 1. About 
There was running a migration project from CDH 4 to CDH5. One of the task was to mirroring Kafka Servers.
There is a tool, the Kafka Mirrormaker which is available for this task. 

Mirrormaker is the part of the Kafka installation. It contains consumer and producer too. The consumer connects to the original Kafka Server and forwards the data to the new one. 
If we are using mirroring different version of Kafka servers, then we must pay attention which version of Kafka is used. 

Due to protocol change, unfortunately Mirrormaker from CDH5 does not work with the Kafka of CDH4. We have to execute it on CDH4. 

To test it I have created the following instruction to create the test environment with Docker.

## 2. Test environment

### 2.1. Requirements

#### 1.	Docker installation - https://docs.docker.com/engine/installation/

### 2.2	Docker image and containers setup 

#### 1. gszecsenyi/kafka Docker image contains only Kafka installations. It starts automatically.

Execute it in Terminal or with Powershell:
```
docker pull gszecsenyi/kafka:0.8.0
docker pull gszecsenyi/kafka:0.9.1
```
#### 2. Now the images were downloaded. The containers will be created with the following commands
```
docker run –d -t -i --name kafka_0.9.1 gszecsenyi/kafka:0.9.1 
```
#### 3. Log in into kafka_0.9.1 container mit the following command
```
docker exec -t -i kafka_0.9.1 /bin/bash
```
#### 4. Get the IP-Adresse with  ifconfig comamnd (inet addr for eth0 interface)
```
root@f335b0c750fd:~# ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:ac:11:00:03  
          	  inet addr: 172.17.0.3  Bcast:0.0.0.0  Mask:255.255.0.0
```
#### 5. Now we add the 0.9.1 kafka servers ip-adress in the 0.8.0's /etc/hosts file entry. 
```
docker run –d -t -i --name kafka_0.8.0 --add-host f335b0c750fd: 172.17.0.3 gszecsenyi/kafka:0.8.0 
```

### 2.3	Creating Kafka Topic and  producer configuration on source side

#### 1.	Log in into kafka_0.8.0 container
```
docker exec -t -i kafka_0.8.0 /bin/bash
```
#### 2.	Create Kafka Topic
```
cd /opt/kafka
bin/kafka-create-topic.sh --zookeeper localhost:2181 --replica 1 --topic topik_1
bin/kafka-list-topic.sh --zookeeper localhost:2181
```
#### 3.	Starting Kafka console consumer in the background
```
bin/kafka-console-consumer.sh --zookeeper localhost:2181 --topic topik_1 &
```
#### 4.	Starting Kafka console producer 
```
bin/kafka-console-producer.sh --broker-list localhost:9092 --topic topik_1
```
#### 5.	Enter some testdata
```
AAAAAAAAA
BBBBBBBB
CCCCCCCC
DDDDDDDD
EEEEEEEE
```

### 2.4	Setup MirrorMaker

#### 1. Log in into  kafka_0.8.0 container 
```
docker exec -t -i kafka_0.8.0 /bin/bash 
```
#### 2. It has to create two configfiles. 

#### 2.1 For source configuration the mm_source.config
```
zookeeper.connect=localhost:2181
consumer.timeout.ms=-1
group.id=MirrorMaker
```

#### 2.2 For target configuration the mm_target.config
```
metadata.broker.list=172.17.0.2:9092
```
## 3. Starting MirrorMaker 

#### 1. We start a new shell in kafka_0.8.0
```
docker exec -t -i kafka_0.8.0 /bin/bash
```
#### 2. Switch directory and execute the following command
```
cd /opt/kafka
bin/kafka-run-class.sh kafka.tools.MirrorMaker --consumer.config mm_source.config --producer.config mm_target.config --whitelist=topik_1
```
## 4. Test Mirrormaker

#### 1. Start a shell in 0.9.1 kafka container
```
docker exec -t -i kafka_0.9.1 /bin/bash
```
#### 2.  Execute the console consumer to check the data from MirrorMaker
```
bin/kafka-console-consumer.sh --zookeeper localhost:2181 --topic topik_1 &
```
#### 3. Put soe test data in the kafka_0.8.0 producer einschreiben
```
XXXXXX
YYYYYY
ZZZZZZ
```
#### 4.	Starting Kafka Offset Checker 
```
bin/kafka-run-class.sh kafka.tools.ConsumerOffsetChecker --group MirrorMaker --zkconnect localhost:2181 --topic topik_1
```

 
