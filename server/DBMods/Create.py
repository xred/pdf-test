from Models import *

def add_user(email,password,nickname):
	user = User(email=email,password=password,nickname=nickname)
	session.add(user)
	session.commit();


add_user("499126563@qq.com","red123123","red")
