# -*- coding:utf-8 -*-
import os
import tornado.ioloop
import tornado.web
import tornado.httpserver
import MySQLdb
import DBMods

from Base import BaseHandler
import Utils
import PDFView
import User

class Main(BaseHandler):
    def get(self):
        self.redirect("/pdfview")

class Ping(BaseHandler):
    def get(self):
        self.write('pong')
        
class NotFoundHandler(BaseHandler):
    def get(self,pathname):
        self.abort(404)
    def post(self,pathname):
        self.abort(404)


current_path =  os.path.dirname(os.path.abspath(__file__))       
settings = {
    "cookie_secret":"41oETzPPXAGLLdkL5g9663JJFuYh7DRdq2XdTP1oAVo=",
    "login_url":"/login",
    "debug":True,
    "static_path":os.path.join(current_path,"../static"),
    "template_path":os.path.join(current_path,"../templates"),
    "ui_modules":{'HomePaperItem': User.HomePaperItemModule},
    "autoescape":None,
    "port":8005,
}

js_path = os.path.join(current_path,"../static/js")
css_path = os.path.join(current_path,"../static/css")
img_path = os.path.join(current_path,"../static/img")
core_path = os.path.join(current_path,"../static/core")

handlers = [
    (r"/", Main),
    (r"/ping", Ping),
    (r"/pdfview", PDFView.Index),
    (r"/pdfview/comment", PDFView.Comment),
    (r"/pdfview/reply", PDFView.Reply),
    (r"/login", User.Login),
    (r"/register",User.Register),
    (r'/logout',User.Logout),
    (r"/home",User.Home),
    (r"/setting",User.Setting),
    # static route
    (r"/static/(.*)",tornado.web.StaticFileHandler,dict(path=settings['static_path'])),
    (r"/js/(.*)",tornado.web.StaticFileHandler,dict(path=js_path)),
    (r"/css/(.*)",tornado.web.StaticFileHandler,dict(path=css_path)),
    (r"/img/(.*)",tornado.web.StaticFileHandler,dict(path=img_path)),
    (r"/core/(.*)",tornado.web.StaticFileHandler,dict(path=core_path)),
    #not found
    (r"/(.*)",NotFoundHandler)
]

application = tornado.web.Application(handlers,**settings)

if __name__ == "__main__":
    print "static_path is",settings['static_path']
    http_server = tornado.httpserver.HTTPServer(application)
    http_server.listen(settings["port"])
    print "backstage management and order handle server start at port %d" % settings["port"]
    tornado.ioloop.IOLoop.instance().start()
