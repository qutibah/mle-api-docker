# Docker Compose
Docker Compose is a tool for defining and running multi-container Docker applications. With Compose, you use a YAML file to configure your application's services. Then, with a single command, you create and start all the services from your configuration. To learn more about Docker Compose, visit the [official documentation](https://docs.docker.com/compose/). You don't need to install Docker Compose separately. It is included in the Docker Desktop installation. The networking part you needed to do in the previous section is now handled by Docker Compose.

## Docker Compose File
A Docker Compose file is a YAML file that specifies the configuration for a Docker application. It specifies the services that make up the application, and the configuration for each service. It is especially handy if you want to configure more than one service at a time. The Docker Compose file for our example is shown below:

```yaml
version: "3.9"

services:
  db:
    image: postgres:13.2
    container_name: postgres_compose
    restart: always
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    ports:
      - "5432:5432"
    volumes:
      - ./postgres-db-volumne:/var/lib/postgres/data

  app:
    build: 
      context: service
      dockerfile: Dockerfile
    container_name: fastapi_compose
    environment:
      DB_CONN: ${DB_CONN}
    ports:
      - "8000:8000"
    depends_on:
      - db
``` 

The Docker Compose file specifies the following:
- The version of the Docker Compose file format to use. In this case, we are using version 3.9.
- The services that make up the application. In this case, we have two services: `db` and `app`.
- The configuration for each service. The configuration for the `db` service specifies the image to use, the container name, the environment variables, the port mapping, and the volume to use. The configuration for the `app` service specifies the build context, the container name, the port mapping, and the dependencies.

Another benefit of docker compose is that in yaml files you can set the environment variables directly in the file. This is done by using the `${}` syntax. This is way you don't need to set the environment variables in the terminal. You can set them directly in the yaml file.

For building the app we need to specify a Dockerfile. We will use the Dockerfile we created earlier in the service folder. The Dockerfile is specified in the build context.

Change the DB_CONN in the .env file to DB_CONN=postgresql://postgres:postgres@postgres_compose:5432/fastapi.

## Running the Docker Compose Application
To run the Docker Compose application, we need to run the following command:

```bash
docker-compose up -d
```

This command will run the Docker Compose application in detached mode. The `-d` flag specifies that the application should run in detached mode.

## Stopping the Docker Compose Application
To stop the Docker Compose application, we need to run the following command:

```bash
docker-compose down
```

This command will stop the Docker Compose application.

## Viewing the Logs
To view the logs for the Docker Compose application, we need to run the following command:

```bash
docker-compose logs -f
```

This command will display the logs for the Docker Compose application. The `-f` flag specifies that the logs should be displayed in real-time.
