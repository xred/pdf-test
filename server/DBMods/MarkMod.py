# -*- coding:utf-8 -*-
from Models import Mark,session,queryWrapper

def add(aid,pageid,x,y,width,height,color):
    mark = Mark(
        articleid = aid,
        pageid = pageid,
        markx = x,
        marky = y,
        markw = width,
        markh = height,
        markcolor = color,
    )
    session.add(mark)
    session.commit()
    return mark
    
def delete():
    pass

@queryWrapper
def query(**selector):
    return session.query(Mark).filter_by(**selector).all()



            
        
