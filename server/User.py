# -*- coding:utf-8 -*-
from Base import BaseHandler
import Utils
from DBMods import UserMod
import time
import tornado.web

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
                res = dict(flag=0,name="a",num=5)
        else:
            res = {"flag":0}
        self.write(res)

class Logout(BaseHandler):
    @Utils.authenticated
    def get(self):
        self.clear_cookie('user')
        self.redirect('/login')
            
class Register(BaseHandler):
    def get(self):
        self.render('register.html',page='register')
    def post(self):
        email = self.get_argument('email')
        print email
        psw = self.get_argument('psw')
        nickname = self.get_argument('nickname')
        if not UserMod.query(email=email) and not UserMod.query(nickname=nickname):
            UserMod.add(email,psw,nickname)
            res = dict(flag=1)
        else:
            res = dict(flag=0)
        self.write(res)

class Home(BaseHandler):
    @Utils.authenticated
    def get(self):
        t = time.strftime("%Y.%m.%d",time.localtime())
        content = 'fuuuuuuuuuuuuuuuuuuuuck'
        comment= dict(comment_name='nmsl',comment_date=t,content = content)
        papers = [{
        "paperid":1,"marks":[
            {"markid":1,"myComments":[comment,comment,comment,comment],"otherComments":[comment,comment,comment,comment]},
            {"markid":2,"myComments":[comment,comment,comment],"otherComments":[comment,comment,comment,comment,comment]},
        ]}
        ]
        data = dict(papers = papers)
        test = papers[0]['marks'][0]['myComments'][0]['comment_name']
        # print test
        self.render('home.html',nickname=self.user_record.nickname,data = data)
    def post(self):
        cmmMarkid = self.get_argument('markid')
        cmmPaperid = self.get_argument('paperid')
        myOrOther = self.get_argument('myOrOther')
       
        t = time.strftime("%Y.%m.%d",time.localtime())
        content = 'fuuuuuuuuuuuuuuuuuuuuck'
        comment= dict(comment_name='nmsl',comment_date=t,content = content)
        papers = [{
        "paperid":1,"marks":[
            {"markid":1,"myComments":[comment,comment,comment,comment],"otherComments":[comment,comment,comment,comment]},
            {"markid":2,"myComments":[comment,comment,comment],"otherComments":[comment,comment,comment,comment,comment]},
        ]}
        ]
        moreComments=[]
        for paper in papers:
            if paper['paperid']==int(cmmPaperid):
                for mark in paper['marks']:
                    if mark['markid']==int(cmmMarkid):
                        if myOrOther=='My comments':
                            moreComments=mark['myComments'][3:]
                        if myOrOther=='Other comments':
                            moreComments=mark['otherComments'][3:]
        res = dict(comment=moreComments)
        time.sleep(1)
        self.write(res)


class HomePaperItemModule(tornado.web.UIModule):
    def render(self,papers):
        return self.render_string('modules/home_paper_item.html', papers=papers)

class Setting(BaseHandler):
    def get(self):
        self.render('setting.html')
