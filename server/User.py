# -*- coding:utf-8 -*-
from Base import BaseHandler
import Utils
from DBMods import UserMod

class Login(BaseHandler):
    def get(self):
        self.render('login.html',page='login')
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
        if not UserMod.query(email=email) and not not UserMod.query(nickname=nickname):
            UserMod.add(email,psw,nickname)
            res = dict(flag=1)
        else:
            res = dict(flag=0)
        self.write(res)

class Home(BaseHandler):
    @Utils.authenticated
    def get(self):
        self.render('home.html',nickname=self.user_record.nickname)

class Logout(BaseHandler):
    @Utils.authenticated
    def get(self):
        self.clear_cookie('user')
        self.redirect('/login')
