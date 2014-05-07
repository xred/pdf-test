from sqlalchemy import *
from sqlalchemy.orm import *
from sqlalchemy import Column
from sqlalchemy.types import CHAR, Integer, String
from sqlalchemy.ext.declarative import declarative_base
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
	'passwd':'xredcn123'
}

engine = create_engine('mysql://%s:%s@%s/%s?charset=%s'%(
	db_config['user'],
	db_config['passwd'],
	db_config['host'],
	db_config['db'],
	db_config['charset']),
	echo=True)
DB_SESSION = sessionmaker(bind=engine)
session = DB_SESSION()

BaseModel = declarative_base()

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
	markx = Column(Integer)
	marky = Column(Integer)
	markw = Column(Integer)
	markh = Column(Integer)
	markx = Column(Integer)
	commentnum = Column(MEDIUMINT(8))

class Comment(BaseModel):
	"""a map of comment map"""
	__tablename__ = "markpaper_comment"
	commentid = Column(MEDIUMINT(8),primary_key=True)
	articleid = Column(MEDIUMINT(8))
	markid = Column(MEDIUMINT(8))
	content = Column(TEXT)
	userid = Column(MEDIUMINT(8))
	username = Column(VARCHAR(255))
	datetime = Column(Integer())
	replynum = Column(MEDIUMINT(8))
	praisenum = Column(MEDIUMINT(8))

def create_tables():
	BaseModel.metadata.create_all(engine)

def drop_db():
	BaseModel.metadata.drop_all(engine)
