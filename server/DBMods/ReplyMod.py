# -*- coding:utf-8 -*-
from Models import Reply,session
import time

def add(cid,content):
    reply = Reply(
        commentid = cid,
        content = content,
        datetime = int(time.time())
    )
    session.add(reply)
    session.commit()
    return reply
    
def query(**selector):
    res = session.query(Reply).filter_by(**selector).all()
    if len(res) == 0:
        return None
    else:
        return res

def update():
    pass

def delete():
    pass

