# -*- coding:utf-8 -*-
import tornado.web
import Utils
from Utils import *

class BaseHandler(tornado.web.RequestHandler):
    "所有Handler的基类,封装一些常用的方法"
    user_record = None
    args = {}
    def abort(self,error_code=400):
        """
        400 : 参数错误
        401 : 没有权限（未登录）
        500 : 服务器错误
        """
        self.set_status(error_code)
        return self.write('<h1>'+str(error_code)+'<h1>')
    def get_current_user(self):
        """
        Tornado会自动调用此方法，将其返回值赋值给self.current_user
        """
        username = self.get_secure_cookie("user")
        if not username:
            return None
        return tornado.escape.xhtml_escape(username)
