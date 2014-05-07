from Models import *

def add_user(email,password,nickname):
	user = User(email=email,password=password,nickname=nickname)
	session.add(user)
	session.commit();


#add_user("test@test.com","123456","test")
