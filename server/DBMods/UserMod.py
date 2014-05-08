# -*- coding:utf-8 -*-
from Models import *

def add(email,password,nickname):
    user = User(email=email,password=password,nickname=nickname)
    session.add(user)
    session.commit();

def query(**selector):
    res = session.query(User).filter_by(**selector).all()
    if len(res) == 0:
        return None
    else:
        return res

def delete(**selector):
    for instance in session.query(User).filter_by(**selector):
        session.delete(instance)
    session.commit()

def update_by_email(email,**update):
    for instance in session.query(User).filter_by(email=email):
        if 'password' in update:
            instance.password = update["password"]
    session.commit()

def update(*args,**kwargs):
    update_by_email(*args,**kwargs)