# Application Programming Interfaces (APIs)

**APIs are a set of protocols and tools that allow different software applications to communicate with each other.** They have become an essential part of modern software development, enabling developers to build complex systems that integrate with other applications seamlessly.

A **REST API (Representational State Transfer API)** is a way for these systems to communicate over the web using standard **HTTP methods** like **`GET`**, **`POST`**, **`PUT`**, and **`DELETE`**. In a REST API, data is organized into resources, each accessible through a **unique URL**.  

**FastAPI is a Python-based web framework** that has gained popularity among developers for its speed, simplicity, and easy-to-use API building capabilities. It leverages the latest Python features and best practices to provide a fast, scalable, and reliable API framework.

FastAPI is built on top of the powerful ASGI server, which allows for high-performance asynchronous code execution. It provides automatic documentation, type checking, and validation, making it easy to create well-documented and robust APIs. FastAPI also includes built-in support for popular data formats like JSON, YAML, and CSV, and integrates seamlessly with popular databases like PostgreSQL and MongoDB.

In summary, FastAPI is a modern and powerful Python-based framework that provides a fast, scalable, and easy-to-use solution for building APIs. Its popularity among developers is rapidly increasing due to its speed, simplicity, and the comprehensive features it provides out of the box.

### Building a FastAPI Application

In this section, we will build a simple FastAPI application that will allow us to explore the features and capabilities of the framework. 

We will use the FastAPI framework to build a simple API in Python. It will allow us to perform basic **CRUD operations** (Create, Update, Read, and Delete: fundamental actions that can be performed on data stored in databases) on a database of users. 

In this example we will use the **Postgres database**, but you can use any database that is supported by FastAPI. We will also use the **SQLAlchemy ORM** to interact with the database. 

You can find the [code](./service/main.py) for this example in the **/service** folder.

#### Creating the Database
We created the database in the [Docker Intro](02-intro-to-docker.md) section.

#### Modular App Structure
When writing an app, it is best to create independent and modular python code. Here we will discuss the following constituent files of our app: **database.py**, **models.py**, **schemas.py**, **main.py** and **load.py**.

Ideally, you should only have to define your database models once! Using SQLAlchemy’s **`declarative_base()`** and **`Base.metadata.create_all()`** allows you to write just one class per table to use in the app, to use in Python outside of the app and to use in the database. With a separate **`database.py`** and **`models.py`** file, we establish our database table classes and connection a single time, then call them later as needed.

To avoid confusion between the SQLAlchemy models and the Pydantic models, we will call the file **`models.py`** with the SQLAlchemy models, and the file **`schemas.py`** with the Pydantic models. Also of note is that SQLAlchemy and Pydantic use slightly different syntax to define models, as seen in the below files.

#### Creating the Database Connection

The **`database.py`** file contains the code to create the database connection. We will use the **SQLAlchemy ORM** to interact with the database. SQLAlchemy is a Python library that provides a simple and powerful abstraction layer for interacting with databases. It allows us to write SQL queries using Python syntax, which makes it easy to build complex queries and perform database operations.

```python
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

load_dotenv()

SQLALCHEMY_DATABASE_URI = os.getenv("DB_CONN")

engine = create_engine(SQLALCHEMY_DATABASE_URI)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()
```

**SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)** is enabling us to interact with the database. The **`autocommit`** and **`autoflush`** are set to **`False`**, which means that SQLAlchemy will not automatically commit changes to the database or automatically refresh objects from the database. The bind parameter is set to the engine we created earlier.

##### Declarative Base and MetaData
The **`declarative_base()`** base class contains a **`MetaData`** object where newly defined Table objects are collected. This MetaData object is accessed when we call the line **`models.Base.metadata.create_all()`** to create all of our tables.

##### os.getenv()
The **`os.getenv()`** function returns the value of the environment variable with the specified name. To not expose our database credentials, we will use environment variables to store the database URI. We will use the **`python-dotenv`** library to load the environment variables from a **`.env`** file. In the **`.env`** file, we will store the database URI as **`DB_CONN`**. In a Docker container, we can pass the environment variables to the container using the **`-e`** flag.

#### Session Local: Handling Threading Issues
SQLAlchemy includes a helper object that helps with the establishment of user-defined Session scopes. This is useful for eliminating threading issues across your app.

To create a session, below we use the **`sessionmaker`** function and pass it a few arguments. Sessionmaker is a factory for initializing new Session objects. Sessionmaker initializes these sessions by requesting a connection from the engine's connection pool and attaching a connection to the new Session object.

```python
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
```

Initializing a new session object is also referred to as **"checking out"** a connection. The database stores a list of these connections/processes. So when you begin a new session, be mindful you are also starting a new process within the database. If the database doesn’t have these connections closed, there is a maximum number of connections that can be reached. The database will eventually kill idle processes like stale connections; however, it can take hours before that happens.

SQLAlchemy has some pool options to prevent this, but **removing the connections when they are no longer needed is best!** The FastAPI docs include a **`get_db()`** function that allows a route to use the same session through a request and then close it when the request is finished. Then **`get_db()`** creates a new session for the next request.

Once we have our database connection and session set up, we are ready to build our other app components.

#### Creating the Database Models

The **`models.py`** file contains the code to create the database models. As before, we will use the SQLAlchemy ORM to interact with the database. 

```python
from sqlalchemy import Boolean, Column, ForeignKey, Integer, String
from database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    email = Column(String, unique=True, index=True)
    password = Column(String)
```

This file creates the model or schema for the table **`users`** in our database.

Using SQLAlchemy’s **`declarative_base()`** allows you to write just one model for each table that the app uses. That model is then used in Python outside of the app and in the database.

Having these separate Python files is good because you can use the same model to query or load data outside of an app. Additionally, you’ll have one version of each model, which simplifies development.

These modular Python files can be used to reference the same models or databases in data pipelines, report generation, and anywhere else they are needed.


#### Creating the Pydantic Models

The **`schemas.py`** file contains the code to create the Pydantic models. Pydantic is a Python library that allows us to define data models using Python type annotations. It provides data validation, serialization, and deserialization out of the box, making it easy to build robust APIs.

```python
from pydantic import BaseModel

class UserModel(BaseModel):
    name: str
    email: str
    password: str

    class Config:
        orm_mode = True
        
class UserOut(BaseModel):
    id: int
    name: str
    email: str
    
    class Config:
        orm_mode = True

class UserUpdate(BaseModel):
    name: str
    email: str
    password: str
    
    class Config:
        orm_mode = True
```

The line **`orm_mode = True`** allows the app to take ORM objects and translate them into responses automatically. This automation saves us from manually taking data out of ORM, making it into a dictionary, then loading it in with Pydantic.
**ORM means Object Relational Mapping.** It is a technique that lets you query and manipulate data from a database using an object-oriented paradigm. It is a programming technique for converting data between incompatible type systems using object-oriented programming languages. This creates, in effect, a **"virtual object database"** that can be used from within the programming language.

#### Creating the Main App File

The **`main.py`** file contains the code to create the FastAPI app. Here is where we bring all the modular components together.

After importing all of our dependencies and modular app components we call **`models.Base.metadata.create_all(bind=engine)`** to create our models in the database.

```python
from fastapi import Depends, FastAPI, HTTPException
import models
import schemas
from database import engine, SessionLocal
from sqlalchemy.orm import Session


app = FastAPI()

models.Base.metadata.create_all(bind=engine)


# Dependency
def get_db():
    try:
        db = SessionLocal()
        yield db
    finally:
        db.close()

@app.get("/")
def index():
    return {"data": "user list"}

# get all user
@app.get("/users", response_model=list[schemas.UserOut])
def get_all_user(db: Session = Depends(get_db)):
    user = db.query(models.User).all()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

# add user
@app.post("/users", response_model=schemas.UserOut)
def create_user(request: schemas.UserModel, db: Session = Depends(get_db)):
    new_user = models.User(name=request.name, email=request.email, password=request.password)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

# update user
@app.put("/users/{id}")
def update_user(id: int, request: schemas.UserUpdate, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == id)
    if not user.first():
        raise HTTPException(status_code=404, detail="User not found")
    user.update(request.dict())
    db.commit()
    return "Updated successfully"

# delete user
@app.delete("/users/{id}")
def delete(id: int, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == id)
    if not user.first():
        raise HTTPException(status_code=404, detail="User not found")
    user.delete(synchronize_session=False)
    db.commit()
    return "Deleted successfully"
```

The **`get_db()`** function ensures that any route passed this function ought to have our SessionLocal database connection when needed and that the session is closed after use.

The **`@app.get()`** decorator is used to define a route, in this case the route is "/users". The **`@app.post()`** decorator is used to define a route that accepts **POST** requests (a HTTP method used to send data to a server). The **`@app.put()`** decorator is used to define a route that accepts **PUT** requests. The **`@app.delete()`** decorator is used to define a route that accepts **DELETE** requests.

#### Table of FastAPI Decorators

| Decorator | HTTP Method | Description |
| --- | --- | --- |
| `@app.get()` | GET | Retrieve data |
| `@app.post()` | POST | Create data |
| `@app.put()` | PUT | Update data |
| `@app.delete()` | DELETE | Delete data |



The **`response_model`** parameter is used to define the response model for the route. The **`Depends()`** function is used to define dependencies for the route. The **`db: Session = Depends(get_db)`** parameter is used to define the database session for the route.

## Running the App

To run the app we can use the **`uvicorn`** command. First you need to move to the **/service** directory (**`cd service`**) and then run the following command (it will run the app on port 8000):

```bash
uvicorn main:app --reload --port 8000
```

If your port is already in use you can use the **`--port`** parameter to specify a different port.
Now that the app is running we can access the docs in the browser at **`http://localhost:8000/docs`**.

## Testing the App
To test the app we can use the docs which you can access in the browser, or we can use the **`curl`** command to send a request to the API. Open a **new Terminal** and type the following command, which will send a **GET** request to the **`/users`** endpoint:

```bash
curl http://localhost:8000/users
```

The response indicates that there is one user in the database. We can add a user by sending a **POST** request to the **`/users`** endpoint:

```bash
curl -X POST http://localhost:8000/users -H "Content-Type: application/json" -d '{"name": "Jane Doe", "email": "jane.doe@example.com", "password": "password1234"}'
``` 

This command will return the following response:

```json
{
    "id": 2,
    "name": "Jane Doe",
    "email": "jane.doe@example.com"
}
```

This response indicates that the user was successfully added to the database. Note that the **password** is not shown, since it's not specified in the **`UserOut`** class ([schemas.py](service/schemas.py)) for security reasons.

We can now send a **GET** request to the **`/users`** endpoint to retrieve the user:

```bash
curl http://localhost:8000/users
```

This command will return all users.

## Conclusion

In this tutorial we learned how to create a REST API using **FastAPI**. We created a simple CRUD API that allows us to create, read, update, and delete users from a database. We also learned how to use **SQLAlchemy** to interact with the database and how to use **Pydantic** to validate and serialize data. Of course **such an API can also be used as an endpoint for Machine Learning models**. It would look something like this:

```python
@app.post("/predict", response_model=schemas.Prediction)
def predict(request: schemas.PredictionRequest, db: Session = Depends(get_db)):
    # get data from request
    # preprocess data
    # make prediction
    # return prediction
```
