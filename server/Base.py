# -*- coding:utf-8 -*-
import tornado.web

class BaseHandler(tornado.web.RequestHandler):
    "所有Handler的基类,封装一些常用的方法"
    user_record = None
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
    def authenticated():
        """
        @装饰器
        主要用于验证用户是否登录，或者验证用户的权限
        """
        def wrapper(self,*args,**kwargs):
            if not self.current_user:
                self.abort(401)
                self.redirect("/")
                return None
            else:
                username = self.current_user
                root_record = db('root').users.find_one({"username":username})
                if not root_record:
                    self.write_error_msg(111)
                    self.redirect("/")
                    return None
                self.area = root_record['area']
                
                self.privLevel = db("root").areas.find_one({"name":self.area})['privLevel']
                self.user_record = db(self.area).users.find_one({"username":username})
                if not self.user_record:
                    # 这里还没有找到就是用户数据出错了，根数据库里的用户名与子数据库用户名不一致
                    self.write_error_msg(101)
                    self.clear_cookie("dspName")
                    self.clear_cookie("user")
                    self.redirect("/")
                    return None
            return func(self,*args,**kwargs)
        return wrapper
