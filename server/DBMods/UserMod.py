# -*- coding:utf-8 -*-
from Models import User,session,queryWrapper

def add(email,password,nickname):
    user = User(email=email,password=password,nickname=nickname)
    session.add(user)
    session.commit();

@queryWrapper    
def query(**selector):
    return session.query(User).filter_by(**selector).all()

def delete(**selector):
    for instance in session.query(User).filter_by(**selector):
        session.delete(instance)
    session.commit()

def update(email,**update):
    for instance in session.query(User).filter_by(**selector):
        if 'password' in update:
            instance.password = update["password"]
    session.commit()

if not query(nickname = "test"):
    add("test@test.com","123456","test")
