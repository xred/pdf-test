# -*- coding:utf-8 -*-
from sqlalchemy import *
from sqlalchemy.orm import *
from sqlalchemy.types import CHAR, Integer, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.schema import Table
from sqlalchemy.dialects.mysql import \
        BIGINT, BINARY, BIT, BLOB, BOOLEAN, CHAR, DATE, \
        DATETIME, DECIMAL, DECIMAL, DOUBLE, ENUM, FLOAT, INTEGER, \
        LONGBLOB, LONGTEXT, MEDIUMBLOB, MEDIUMINT, MEDIUMTEXT, NCHAR, \
        NUMERIC, NVARCHAR, REAL, SET, SMALLINT, TEXT, TIME, TIMESTAMP, \
        TINYBLOB, TINYINT, TINYTEXT, VARBINARY, VARCHAR, YEAR

#input password
db_config = {
    'host':'localhost',
    'user':'root',
    'db':'markpaper',
    'charset':'utf8',
    'passwd':''
}

engine = create_engine('mysql://%s:%s@%s/%s?charset=%s'%(
    db_config['user'],
    db_config['passwd'],
    db_config['host'],
    db_config['db'],
    db_config['charset']),
        echo=False)
DB_SESSION = sessionmaker(bind=engine)
session = DB_SESSION()

BaseModel = declarative_base()

#object

class User(BaseModel):
    """a map of user table"""
    __tablename__ = "markpaper_user"        
    uid = Column(MEDIUMINT(8),primary_key=True)
    email = Column(VARCHAR(255))
    nickname = Column(VARCHAR(255))
    fullname = Column(VARCHAR(255))
    password = Column(VARCHAR(255))
    groupid = Column(MEDIUMINT(8))
    competence = Column(Integer)
    credits = Column(MEDIUMINT(8))
    emailstatus = Column(Integer)
    varificationstatus = Column(Integer)
    bio = Column(TEXT)
    institute = Column(VARCHAR(255))
    commentnum = Column(MEDIUMINT(8))
    replynum = Column(MEDIUMINT(8))
    registertime = Column(Integer)

class Mark(BaseModel):
    """a map of mark table"""
    __tablename__ = "markpaper_mark"
    markid = Column(MEDIUMINT(8),primary_key=True)
    articleid = Column(VARCHAR(30))
    pageid = Column(Integer)
    markx = Column(Integer)
    marky = Column(Integer)
    markw = Column(Integer)
    markh = Column(Integer)
    markcolor = Column(Integer)
    commentnum = Column(MEDIUMINT(8))

class Comment(BaseModel):
    """a map of comment map"""
    __tablename__ = "markpaper_comment"
    commentid = Column(MEDIUMINT(8),primary_key=True)
    articleid = Column(VARCHAR(30))
    markid = Column(MEDIUMINT(8))
    content = Column(TEXT)
    userid = Column(MEDIUMINT(8))
    nickname = Column(VARCHAR(255))
    datetime = Column(Integer)
    replynum = Column(MEDIUMINT(8))
    praisenum = Column(MEDIUMINT(8))
    
class Reply(BaseModel):
    """a map of reply map"""
    __tablename__ = "markpaper_reply"
    replyid = Column(MEDIUMINT(8),primary_key=True)
    commentid = Column(MEDIUMINT(8))
    content = Column(TEXT)
    userid = Column(MEDIUMINT(8))
    nickname = Column(VARCHAR(255))
    datetime = Column(Integer)
    praisenum = Column(MEDIUMINT(8))
    

#relation
#http://docs.sqlalchemy.org/en/rel_0_9/orm/relationships.html
vote_for_comment_relation = Table('vote_for_comment_relation',BaseModel.metadata,
    Column('commentid', MEDIUMINT(8), ForeignKey('markpaper_comment.commentid')),
    Column('uid', MEDIUMINT(8), ForeignKey('markpaper_user.uid')),
    Column('type',Integer),
    Column('datetime',Integer)
    )


#operation
def queryWrapper(func):
    """
    @deco
    """
    def wrapper(toDict = False,*args,**kwargs):
        resList = []
        res = func(*args,**kwargs)
        if len(res) == 0:
            return None
        if not toDict:
            return res;
        else:
            for i in res:
                del i.__dict__['_sa_instance_state']
                resList.append(i.__dict__)
            return resList
    return wrapper

def create_tables():
    BaseModel.metadata.create_all(engine)

def drop_db():
    BaseModel.metadata.drop_all(engine)


