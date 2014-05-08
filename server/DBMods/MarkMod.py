# -*- coding:utf-8 -*-
from Models import Mark,session

def add(x,y,width,height):
    mark = Mark(
        markx = x,
        marky = y,
        markw = width,
        markh = height
    )
    session.add(mark)
    session.commit()
    return mark
    
def delete():
    pass

def query(**selector):
    res = session.query(Mark).filter_by(**selector).all()
    if len(res) == 0:
        return None
    else:
        return res
        
