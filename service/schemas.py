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