# -*- coding:utf-8 -*-
from Base import BaseHandler
import Utils
from DBMods import UserMod
import MySQLdb
conn = MySQLdb.connect(host='localhost',user='root',passwd='',db='markpaper')
cursor = conn.cursor()

class Login(BaseHandler):
    def get(self):
        if self.get_secure_cookie('user') is None:
            self.render('login.html',page='login')
            # UserMod.update('fuck@fuck.fuck',password='fuck')
        else:
            self.redirect('/home')
    def post(self):
        email = self.get_argument('email')
        # print email
        psw = self.get_argument('psw')
        checkEmail = UserMod.query(email=email)
        if checkEmail != None:
            checkPassword = checkEmail[0].password
            if checkPassword == psw:
                res = dict(flag=1)
                self.set_secure_cookie('user',email)
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
        check = UserMod.query(email=email)
        print check
        if check is None:
            # print '1'
            res = dict(flag=1)
            UserMod.add(email,psw,nickname)
        else:
            # print '2'
            res = dict(flag=0)
        self.write(res)

class Home(BaseHandler):
    @Utils.authenticated
    def get(self):
        self.render('home.html')

class Logout(BaseHandler):
    @Utils.authenticated
    def get(self):
        self.clear_cookie('user')
        self.redirect('/login')
