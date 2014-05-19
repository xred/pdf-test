# -*- coding:utf-8 -*-
from Models import Comment,session,queryWrapper
import time

def add(uid,nickname,aid,mid,content):
    comment = Comment(
        content = content,
        userid = uid,
        nickname = nickname,
        articleid = aid,
        markid = mid,
        replynum = 0,
        praisenum = 0,
        datetime = int(time.time()),
    )
    session.add(comment)
    session.commit()
    return comment
    
@queryWrapper    
def query(**selector):
    return session.query(Comment).filter_by(**selector).all()

def delete(**selector):
    pass

def update(commentid,**update):
    session.query(Comment).filter_by(commentid=commentid).update(update,synchronize_session=False)
    #session.commit()
