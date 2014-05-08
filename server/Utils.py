# -*- coding:utf-8 -*-
def parse_json():
    try:
        data = tornado.escape.json_decode(string)
        return data
    except:
        return None
        
def check_type(value,Type):
    if not Type or Type == "all":
        return value
    if (Type == "str" or Type == "string") and type(value) != str:
        try:
            return str(value)
        except:
            return False
    if Type == "int" and type(value) != int:
        try:
            return int(value)
        except:
            return False
    if Type == "float" and type(value) != float:
        try:
            return float(value)
        except:
            return False
    if Type == "number" and type(value) != int and type(value) != float:
        try: return int(value)
        except: pass
        try: return float(value)
        except: pass
        return False
    if (Type == "list" or Type == "array") and type(value) != list:
        try:
            return list(value)
        except:
            return False
    if (Type == "dict") and type(value) != dict:
        try:
            return dict(value)
        except:
            return False
    return value
            
def authenticated(func):
    """
    @装饰器
    主要用于验证用户是否登录，或者验证用户的权限
    """
    def wrapper(self,*args,**kwargs):
        "self is instance of BaseHandler"
        if not self.current_user:
            self.abort(401)
            self.redirect("/login")
            return None
        return func(self,*args,**kwargs)
    return wrapper
    
def check_arguments(*request_arguments):
    """
    @Decorator( request_arguments:string(...) )
    这个装饰器可以配合 Handler 进行参数的检查
    每一个参数是一个字符串，形如 name[:type][?]
    type是类型，可以为 int，str等，? 代表参数是否可选
    参数会从请求的url中解析，或从post的body中以json的方式寻找
    """
    def func_wrapper(method):
        def wrapper(self,*args,**kwargs):
            "self is instance of BaseHandler"
            if self.request.method == "POST":
                obj = parse_json(self.request.body) or {}
                for name in request_arguments:
                    if name.count(':'):
                        Type = name.split(":")[1]
                        name = name.split(":")[0]
                    else:
                        Type = "all"
                    if name.count('?') == 0 and Type.count("?") == 0:
                        if name not in obj:
                            try:
                                obj[name] = self.get_argument(name)
                            except:
                                return self.abort(400)
                    name = name.replace("?",'',1)
                    Type = Type.replace("?",'',1)
                    if name in obj:
                        obj[name] = check_type(obj[name],Type)
                        if obj[name] is False:
                            return self.abort(400)
            else:
                obj = {}
                for name in request_arguments:
                    if name.count(':'):
                        Type = name.split(":")[1]
                        name = name.split(":")[0]
                    else:
                        Type = "all"
                    if name.count('?') > 0 or Type.count("?") > 0:
                        name = name.replace('?','',1)
                        try:obj[name] = self.get_argument(name)
                        except:pass
                    else:
                        try:obj[name] = self.get_argument(name)
                        except: return self.abort(400)
                    Type = Type.replace("?",'',1)
                    if name in obj:
                        obj[name] = check_type(obj[name],Type)
                        if obj[name] is False:
                            return self.abort(400)
            self.args = obj
            return method(self,*args,**kwargs)
        return wrapper
    return func_wrapper

