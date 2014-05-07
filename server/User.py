# -*- coding:utf-8 -*-
from Base import BaseHandler
import DBMods
import MySQLdb
conn = MySQLdb.connect(host='localhost',user='root',passwd='',db='markpaper')
cursor = conn.cursor()

class Login(BaseHandler):
    def get(self):
        self.render('login.html',page='login')
    def post(self):
        email = self.get_argument('email')
        # print email
        psw = self.get_argument('psw')
        # thePsw = cursor.execute('select password from user where email="%s"'%email)
        # thePsw = cursor.fetchone()
        checkEmail = DBMods.Query.query_user(email=email)
        if checkEmail != None:
            checkPassword = checkEmail[0].password
            if checkPassword == psw:
                res = dict(flag=1)
                self.set_secure_cookie('cookie_email',self.get_argument('email'))
            else:
                res = dict(flag=0,naem="a",num=5)
        else:
            res = {"flag":0}
        self.write(res)
            
class Register(BaseHandler):
    def get(self):
        self.render('register.html',page='register')
    def post(self):
        email = self.get_argument('email')
        psw = self.get_argument('psw')
        nickname = self.get_argument('nickname')
        print nickname
        check = DBMods.Query.query_user(email=email)
        print check
        if check is None:
            # print '1'
            res = dict(flag=1)
            DBMods.Create.add_user(email,psw,nickname)
        else:
            # print '2'
            res = dict(flag=0)
        self.write(res)

class Home(BaseHandler):
    # @BaseHandler.authenticated
    def get(self):
        self.render('home.html')