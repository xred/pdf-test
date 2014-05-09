# -*- coding:utf-8 -*-
from Models import Reply,session,queryWrapper
import time

def add(cid,uid,nickname,content):
    reply = Reply(
        commentid = cid,
        userid = uid,
        nickname = nickname,
        content = content,
        datetime = int(time.time())
    )
    session.add(reply)
    session.commit()
    return reply
    
@queryWrapper    
def query(**selector):
    return session.query(Reply).filter_by(**selector).all()

def update():
    pass

def delete():
    pass

