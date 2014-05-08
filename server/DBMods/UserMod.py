# -*- coding:utf-8 -*-
from Models import *

def add(email,password,nickname):
    user = User(email=email,password=password,nickname=nickname)
    session.add(user)
    session.commit();

def query(**selector):
    cursor = session.query(User).filter_by(selector).all()
    if len(res) == 0:
        return None
    else:
        return res

def delete(**selector):
    pass

def update(**selector):
    pass
