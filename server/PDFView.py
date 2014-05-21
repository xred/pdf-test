# -*- coding:utf-8 -*-
from Base import BaseHandler
import Utils
from DBMods import CommentMod,MarkMod,ReplyMod

class Index(BaseHandler):
    @Utils.authenticated
    def get(self):
        self.render("pdfview.html",nickname=self.user_record.nickname)
        
class Comment(BaseHandler):
    @Utils.check_arguments("aid","id:int?","markid:int?")
    def get(self):
        """
        Get single comments or all comment for one article
        """
        if "id" in self.args:
            comments = CommentMod.query(True,commentid = self.args["id"])
            if comments:
                self.write(dict(success = True,comment = comments[0]))
            else:
                self.write(dict(success = True,comment = None))
        elif "markid" in self.args:
            comments = CommentMod.query(True,markid = self.args['markid'])
            if not comments : comments = []
            self.write(dict(success = True,comments = comments))
        else:
            comments = CommentMod.query(True,articleid = self.args['aid'])
            marks = MarkMod.query(True,articleid = self.args['aid'])
            print comments,marks
            if not comments : comments = []
            if not marks: marks = []
            self.write(dict(success = True,comments = comments,marks = marks))

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
            uid = self.user_record.uid
            nickname = self.user_record.nickname
            new_comment = CommentMod.add(uid,nickname,aid,mid,content)
            self.write(dict(success=True,commentid=new_comment.commentid))
        elif "markdata" in self.args:
            new_mark = self.add_mark(self.args["markdata"])
            if not new_mark:
                return self.abort(400)
            mid = new_mark.markid
            uid = self.user_record.uid
            nickname = self.user_record.nickname
            new_comment = CommentMod.add(uid,nickname,aid,mid,content)
            self.write(dict(success=True,commentid=new_comment.commentid))
        else:
            self.abort(400)
    def add_mark(self,data):
        x = data["x"]
        y = data["y"]
        w = data["w"]
        h = data['h']
        pageid = data['pageid']
        color = data['color']
        new_mark = MarkMod.add(self.args['aid'],pageid,x,y,w,h,color)
        return new_mark
    def update_content(self):
        pass
        
    @Utils.check_arguments("commentid:int")
    def voteup(self):
        cid = self.args['commentid']
        res = CommentMod.query(commentid = cid)
        if not res:
            self.write(dict(success=False , error_msg = "invailid comment id"))
            return
        oldNum = res[0].praisenum
        CommentMod.update(self.args['commentid'],praisenum = oldNum+1)
        self.write(dict(success=True,praisenum = oldNum+1))
        
    @Utils.check_arguments("commentid:int")
    def votedown(self):
        cid = self.args['commentid']
        res = CommentMod.query(commentid = cid)
        if not res:
            self.write(dict(success=False , error_msg = "invailid comment id"))
            return
        oldNum = res[0].praisenum
        CommentMod.update(self.args['commentid'],praisenum = oldNum-1)
        self.write(dict(success=True,praisenum = oldNum-1))

    
class Reply(BaseHandler):
    @Utils.authenticated
    @Utils.check_arguments("commentid")
    def get(self):
        res = ReplyMod.query(True,commentid = self.args['commentid'])
        self.write(dict(success=True,replys=res))
        
    @Utils.authenticated
    @Utils.check_arguments("action")
    def post(self):
        action = self.args['action']
        if action == "add":
            self.add_reply()
        elif action == "updateContent":
            pass
        elif action == "voteup":
            pass
    @Utils.check_arguments("commentid","content")
    def add_reply(self):
        new_reply = ReplyMod.add(self.args["commentid"],
                              self.user_record.uid,
                              self.user_record.nickname,
                                 self.args["content"])
        self.write(dict(success = True,replyid = new_reply.replyid))

    def update_content(self):
        pass

    def voteup(self):
        pass
