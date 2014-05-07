from Models import *

def query_user(**argv):
    if "email" in argv:
        email = argv['email']
        cursor = session.query(User).filter(User.email == email)
        return cursor.all()
    else:
        return null
