from Models import *

def query_user(**argv):
    if "email" in argv:
        email = argv['email']
        res = session.query(User).filter(User.email == email).all()
        if not len(res):
            return None
        else:
            return res
    else:
        res = session.query(User).all()
        if not len(res):
            return None
        else:
            return res
