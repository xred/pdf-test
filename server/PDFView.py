# -*- coding:utf-8 -*-
from Base import BaseHandler
import Utils
from DBMods import CommentMod,MarkMod,ReplyMod

class Index(BaseHandler):
    def get(self):
        self.render("pdfview.html")
        
class Comment(BaseHandler):
    @Utils.check_arguments("aid:int","id:int?","markid:int?")
    def get(self):
        """
        Get single comments or all comment for one article
        """
        if "id" in self.args:
            res = CommentMod.query(commentid = self.args["id"])
        elif "markid" in self.args:
            res = CommentMod.query(markid = self.args['markid'])
        else:
            res = CommentMod.query(articleid = self.args['aid'])
        self.write(dict(success = True,comments = res))

    @Utils.authenticated
    @Utils.check_arguments("action")
    def post(self):
        action = self.args['action']
        if action == "add":
            self.add_comment()
        elif action == "updateContent":
            self.update_content()
        elif action == "voteup":
            self.voteup()
        elif action == "votedown":
            self.votedown()
        else:
            self.abort(400)
            
    @Utils.check_arguments("content","aid","markid?","markdata?")
    def add_comment(self):
        content = self.args['content']
        aid = self.args['aid']
        if "markid" in self.args:
            mid = self.args["markid"]
            if not MarkMod.query(markid = mid):
                return self.write(dict(success = False,error_msg = "invailid markid"))
            CommentMod.add(self.user_record['uid'],aid,mid,content)
        elif "markdata" in self.args:
            data = self.args['markdata']
            try:
                x = data["x"]
                y = data["y"]
                w = data["w"]
                h = data['h']
            except:
                self.abort(400)
            new_mark = MarkMod.add(x,y,w,h)
            mid = new_mark.markid
            CommentMod.add(self.user_record['uid'],aid,mid,content)
        else:
            self.abort(400)
    def update_content(self):
        pass
    def voteup(self):
        pass
    def votedown(self):
        pass
    
class Reply(BaseHandler):
    @Utils.authenticated
    @Utils.check_arguments("action")
    def post(self):
        action == self.args['action']
        if action == "add":
            pass
        elif action == "updateContent":
            pass
        elif action == "voteup":
            pass
            
    def add_reply(self):
        pass

    def update_content(self):
        pass

    def voteup(self):
        pass
