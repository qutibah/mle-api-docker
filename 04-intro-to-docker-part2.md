# FastAPI and Docker

Now that we created the API that connects to the Database, we can create a Docker image for the API and run it in a container. We will use the Dockerfile that we created in the previous section to create the Docker image. We will also use the **docker-compose.yml** file to run the API in a container.

For that please create a Dockerfile in the **\service** folder with the following content:

```Dockerfile
# Use the official Python image as the base image
FROM python:3.11.3-slim-buster

# Set the working directory
WORKDIR /app

# Copy the application code to the working directory
COPY . /app

# Install the dependencies
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Expose the port
EXPOSE 8000

# Run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

The Dockerfile specifies the following:
- The **base image** to use for building the image. In this case, we are using the official Python image, which is based on the Debian Linux distribution.
- The **working directory**, which is the directory where the application code will be copied to.
- The **application code** to copy to the working directory.
- The **dependencies** to install.
- The **port** to expose. When we run the container, we will map this port to a port on the host machine. This makes the port accessible from outside the container.
- The **command** to run when the container starts.

Change the **`DB_CONN`** in the **`.env`** file to **`DB_CONN='postgresql://postgres:postgres@postgres_cont:5432/fastapi_db'`**.


## Building the Docker Image
To build the Docker image, we need to run the following command inside the **/service** folder:

```bash
docker build -t fastapi_im .
```

This command will build the Docker image using the Dockerfile in the current directory. The **`-t`** flag specifies the name of the image, and the **`.`** specifies the path to the Dockerfile.

## Networking in Docker
**Docker containers are isolated from each other.** This means that they can’t communicate with each other by default. This isolation is a good thing, because it prevents containers from interfering with each other. However, it also means that we need to configure the networking to allow containers to communicate with each other. In the real world, beyond the realm of the simple hello-world tutorial, running just one container isn’t enough for most apps. A modern application typically consists of a few components – such as a **database**, a **web server**, or some **microservices**.

So if you want to run all of your components in containers, how can the applications talk to each other?

How do containers communicate with each other, if they’re supposed to be isolated?

We’ll look at simple communication between Docker containers, when they are running on the same host (which is sometimes called **single-host networking**). Of course it is different in the cloud where you have other Virtual Machines or Containers running on different hosts or even other cloud solutions like bigquery, cloud storage, etc, that the Docker container needs to communicate with.

Two containers can talk to each other in one of two ways, usually:

- **Communicating through networking**: Containers are designed to be isolated. But they can send and receive requests to other applications, using networking. For example: a web server container might expose a port, so that it can receive requests on port 80. Or an application container might make a connection to a database container.

- **Sharing files on disk**: Some applications communicate by reading and writing files. These kinds of applications can communicate by writing their files into a volume, which can also be shared with other containers.

We’ll look at applications that use networking as the primary way: they either expose or consume services. We’ll talk about how to set up a network, which allows Docker containers on the same host to communicate with other.

### Building your (Virtual) Network
Docker containers can communicate with each other using a virtual network. The simplest network in Docker is the **bridge network**. It’s also Docker’s default networking driver. In a bridge network, each container is assigned its **own IP address**. So containers can communicate with each other by IP. But if you use the default bridge network, it means **every container can see every other container**.
To get the IP address of a container, we can use the **`docker inspect`** command:

```bash
docker inspect <container_id> | grep IPAddress
```

If you only use the default bridge network, then all your containers can see and access other containers’ ports. This isn’t always what you want.
**Another “feature” of the default bridge network, is that containers can only talk to each other by their IP address**. Obviously, this is a bit brittle, because IP addresses can change. 
The second option, **the user-defined bridge, lets you have a bit more control**. In a user-defined bridge network, you can be more explicit about who joins the network, and you get an added bonus:

**…containers can be addressed by their name or alias.**


To create a virtual network, we can use the **`docker network create`** command:

```bash
docker network create <network_name>
```

This command will create a virtual network with the specified name.

To list all the virtual networks, we can use the **`docker network ls`** command:

```bash
docker network ls
```

This command will list all the virtual networks.

### Connecting Containers to a Network

To connect a container to a virtual network, we can use the **`docker network connect`** command:

```bash
docker network connect <network_name> <container_id>
```

This command will connect the container with the specified ID to the virtual network with the specified name.

To find the id of the container, we can use the **`docker ps`** command:

```bash
docker ps
```

So please add the postgres container to the network you created before.

### Running the FastAPI Container
To run the Docker container, we need to run the following command:

```bash
docker run -d --name fastapi_cont --network <network_name> -e DB_CONN='postgresql://postgres:postgres@postgres_cont:5432/fastapi_db' -p 8000:8000 fastapi_im
```

This command will run the Docker container in detached mode, mapping the port 8000 on the host machine to the port 8000 on the container. The **`-d`** flag specifies that the container should run in detached mode, and the **`-p`** flag specifies the port mapping. The **`-e`** flag specifies the environment variable that is used to connect to the database.  

Did you notice how, in the SQLAlchemy connection string, we used the name of the postgres container as the host instead of localhost, like we did in the **`.env`** file? This is because the container is now **running in the same network** as the postgres container and can be addressed now by using its name as the hostname: when two containers are joined to the same user-defined bridge network, one container is able to address another by using its name (as the hostname).


#### Table of Docker run flags

| Flag | Description |
| --- | --- |
| `-d` | Run the container in detached mode (in the background) |
| `--name` | Name of the container |
| `--network` | Name of the network to connect to |
| `-e` | Environment variable |
| `-p` | Port mapping |



### TL;DR

- For containers to communicate with each other, they need to be part of the same “network”.

- Docker creates a virtual network called bridge by default, and connects your containers to it.

- In the network, containers are assigned an IP address, which they can use to address each other.

- If you want more control (and you definitely do), you can create a user-defined bridge, which will give you the added benefit of hostnames for your containers too.


## Stopping the container

Please stop the containers using the **`docker stop`** command:

```bash
docker stop <container_id>
```


To find the id of the container, use the **`docker ps`** command:

```bash
docker ps
```





## Summary
In these lessons we learned about **Docker** and how to use it to build and run Docker images and containers. We also learned how to test the Docker container by sending requests to the FastAPI application. Finally, we learned how to connect different containers manually through a network.

In the next lesson we'll learn how to use **Docker Compose** to build, run and orchestrate our multi-container Docker application using a single file.