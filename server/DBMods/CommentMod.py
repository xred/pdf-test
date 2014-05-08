# -*- coding:utf-8 -*-
from Models import Comment,session
import time

def add(uid,aid,mid,content):
    comment = Comment(
        content = content,
        userid = uid,
        articleid = aid,
        markid = mid,
        replynum = 0,
        praisenum = 0,
        datetime = int(time.time())
    )
    session.add(comment)
    session.commit()
    return comment
    
def query(**selector):
    res = session.query(Comment).filter_by(**selector).all()
    if len(res) == 0:
        return None
    else:
        return res

def delete(**selector):
    pass

def update(**selector):
    pass
