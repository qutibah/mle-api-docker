# Docker
**Docker is a popular platform for building, shipping, and running applications in containers.** Containers provide a lightweight and portable way to package and deploy software, allowing applications to run consistently across different environments, from development to production. Docker provides an easy-to-use interface for managing containers and images, making it easier for developers to create, test, and deploy applications.

With Docker, you can package an application and its dependencies into a container image, which can be easily shared and run on any system that supports Docker. Docker images can be built using a Dockerfile, which specifies the configuration of the container, such as the base image, environment variables, and application code.

Docker also provides a registry for storing and sharing Docker images, called **Docker Hub**, which contains a vast collection of pre-built images that can be used as a starting point for building custom images. But you can also create your own registry. Additionally, Docker provides a network interface for connecting containers and services, and a volume system for managing data persistence.

Overall, Docker provides a powerful and flexible toolset for developing and deploying applications in a containerized environment, helping to streamline the development and deployment process and improve application reliability and scalability.

Let's take a look at how we can use Docker to build and run a simple FastAPI application.

## Creating a Dockerfile
For building a Docker image, we need to create a Dockerfile. **A Dockerfile is a text file that contains the instructions for building a Docker image.** It specifies the base image, environment variables, and application code that will be used to build the image. 

First we need a Dockerfile for our database. We will use the official PostgreSQL image as the base image. The Dockerfile for our database is shown below:

```Dockerfile
# Use the official PostgreSQL image as the base image
FROM postgres:17

# Set the working directory
WORKDIR /app

# Expose the port
EXPOSE 5432

# Run the application
CMD ["postgres"]    
``` 

The Dockerfile specifies the following:
- The **base image** to use for building the image. In this case, we are using the official PostgreSQL image, which is based on the Debian Linux distribution.
- The **working directory**, which is the directory where the application code will be copied to.
- The **port** to expose. When we run the container, we will map this port to a port on the host machine. This makes the port accessible from outside the container.
- The **command** to run when the container starts.

You could add environment variables to the Dockerfile, but it is better to use a **`.env`** file or the **`-e`** flag for this. We will see how to do this in the next section.

## Building the Docker Image
To build the Docker image, we need to run the following command in the Terminal (make sure Docker Desktop is **open**):

```bash
docker build -t postgres_im .
```

This command will build the Docker image using the Dockerfile in the current directory. The **`-t`** flag specifies the name of the image, and the **`.`** specifies the path to the Dockerfile.


## Running the Database Container
A **Docker container** is defined as a **running instance of a Docker image**. To run the database container, we need to run the following command:

```bash
docker run -d --name postgres_cont \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_PASSWORD=postgres \
    -e POSTGRES_DB=fastapi_db \
    -v $(pwd)/postgres-db-volume:/var/lib/postgresql/data \
    -p 5432:5432 \
    postgres_im
```

This command will run the container in detached mode, which means that the container will run in the background. The **`--name`** flag specifies the name of the container, and the **`-p`** flag specifies the port mapping. The first port number is the port on the host machine, and the second port number is the port on the container. In this case, we are mapping the port 5432 on the host machine to the port 5432 on the container. The **`-e`** flag specifies the environment variables. The **`POSTGRES_USER`** environment variable specifies the username for the database, the **`POSTGRES_PASSWORD`** environment variable specifies the password for the database, and the **`POSTGRES_DB`** environment variable specifies the name of the database. You could also specify these environment variables in a **`.env`** file, and then use the **`--env-file`** flag to specify the path to the **`.env`** file.
The last argument is the name of the image. The **`-v`** flag is for mounting a volume. The first argument is the path to the volume on the host machine, and the second argument is the path to the volume on the container. In this case, we are mounting the **`postgres-db-volumne`** directory on the host machine to the **`/var/lib/postgresql/data`** directory on the container. This will allow us to persist the data in the database.

#### Used flags as a table

| Flag | Description |
| --- | --- |
| `-d` | Run the container in detached mode |
| `--name` | Specify the name of the container |
| `-p` | Specify the port mapping |
| `-e` | Specify the environment variables |
| `-v` | Mount a volume |
| `-t` | Specify the name of the image |
| `--env-file` | Specify the path to the `.env` file |

## Connecting to the Database
To connect to the database, we need to use a database client. We can use the **`psql`** command-line tool to connect to the database. To connect to the database, we need to run the following command:

```bash
psql -h localhost -p 5432 -U postgres -d fastapi_db
```

This command will connect to the database using the **`psql`** tool. The **`-h`** flag specifies the host, the **`-p`** flag specifies the port, the **`-U`** flag specifies the username and the **`-d`** flag specifies the name of the database. The default **password** for the **`postgres`** user is **`postgres`**.

## Creating the Database
We already defined a database named **`fastapi_db`** in the env variables in the Dockerfile. But we could also create the database using the following command:

```sql
CREATE DATABASE fastapi_db;
```
This command will create a database named **`fastapi_db`**.

## Creating the Table
To create the table, we need to run:

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(50) NOT NULL,
    password VARCHAR(50) NOT NULL
);
```

This command will create a table named **`users`** with the following columns:
- `id`: The primary key for the table.
- `name`: The name of the user.
- `email`: The email address of the user.
- `password`: The password of the user.

## Inserting Data
To insert data into the table, we need to run the following command:

```sql
INSERT INTO users (name, email, password) VALUES ('John Doe', 'john.doe@example.com', 'password');
```

This command will insert a new row into the table with the following values:
- `name`: `John Doe`
- `email`: `john.doe@example.com`
- `password`: `password`

## Querying Data
To query data from the table, we need to run the following command:

```sql
SELECT * FROM users;
```

This command will return all the rows from the table.

Now we created a database and a table, and we inserted some data into the table. We can now use this database in our FastAPI application.  

But first, exit the client with **`\q`**.  

### Common `psql` commands

| Command         | Description                                  |
|-----------------|----------------------------------------------|
| `\l`            | List all databases                           |
| `\c <db_name>`  | Connect to a specific database               |
| `\d`            | List all tables, views, and sequences        |
| `\dt`           | List all tables                              |
| `\?`            | List all `psql` commands                     |
| `\h`            | Show SQL command help (e.g., `\h SELECT`)    |
| `\q`            | Quit the `psql` client                       |

## Stopping the container

To stop the container, we can use the **`docker stop`** command:

```bash
docker stop <container_id>
```

This command will stop the container with the specified ID.

To find the ID of the container, we can use the **`docker ps`** command:

```bash
docker ps
```

This command will list all running containers.

But for now we need the container to be running so we can continue with the next steps.

If you stopped the container, you can start it again by:

```bash
docker start <container_id>
```