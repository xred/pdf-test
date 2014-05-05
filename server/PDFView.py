# -*- coding:utf-8 -*-
from Base import BaseHandler

class Index(BaseHandler):
    def get(self):
        self.render("pdfview.html")
