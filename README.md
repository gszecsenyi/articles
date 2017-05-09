# dockerfile-twitter2kafka
## Version Apache Nifi 1.2.0 
## Version Apache Kafka 0.10.1.0

### Apache Nifi and Kafka pull Twitter Stream from Twitter API and push into Kafka

## Sample Usage

From your checkout directory:
		
1. Build the image

        docker build -t gszecsenyi/twitter2kafka .
		
2. Run the image 

		docker run -i --name twitter2kafka 
				-p 8080:8080 
				-p 2181:2181 
				-p 9092:9092 
				-t gszecsenyi/twitter2kafka 


	`-p 8080:8080`
	exposes the UI at port 8080 on the Docker host system
		
3. Access through your Docker host system
 	
		http://localhost:8080/nifi
		
5. Stopping
		
* From the terminal used to start the container above, perform a `Ctrl+C` to send the interrupt to the container.
* Alternatively, execute a docker command for the container via a `docker stop <container id>` or `docker kill <container id>`

		
## Conventions
### $NIFI_HOME
- The Dockerfile specifies an environment variable `NIFI_HOME` via the `ENV` command

