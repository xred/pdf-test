# -*- coding:utf-8 -*-
import os
import tornado.ioloop
import tornado.web
import tornado.httpserver
import MySQLdb

from Base import BaseHandler
import PDFView

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

settings = {
    "cookie_secret":"41oETzPPXAGLLdkL5g9663JJFuYh7DRdq2XdTP1oAVo=",
    "login_url":"/login",
    "debug":True,
    "static_path":os.path.join(os.path.dirname(os.path.abspath(__file__)),"../static"),
    "template_path":os.path.join(os.path.dirname(os.path.abspath(__file__)),"../templates"),
    "autoescape":None,
    "port":8005,
}

handlers = [
    (r"/", Main),
    (r"/ping", Ping),
    (r"/pdfview", PDFView.Index),
    (r"/static/(.*)",tornado.web.StaticFileHandler,dict(path=settings['static_path'])),
    (r"/(.*)",NotFoundHandler)
]

application = tornado.web.Application(handlers,**settings)

if __name__ == "__main__":
    print "static_path is",settings['static_path']
    http_server = tornado.httpserver.HTTPServer(application)
    http_server.listen(settings["port"])
    print "backstage management and order handle server start at port %d" % settings["port"]
    tornado.ioloop.IOLoop.instance().start()
