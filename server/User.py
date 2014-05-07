# -*- coding:utf-8 -*-
from Base import BaseHandler
import sql_orm
import MySQLdb
conn = MySQLdb.connect(host='localhost',user='root',passwd='anyue125233',db='markpaper')
cursor = conn.cursor()

class Login(BaseHandler):
	def get(self):
		self.render('login.html',page_title='login')
	def post(self):
		email = self.get_argument('email')
		print email
		psw = self.get_argument('psw')
		thePsw = cursor.execute('select password from user where email="%s"'%email)
		thePsw = cursor.fetchone()
		if thePsw != None:
			thePsw = thePsw[0]
			if thePsw == psw:
				self.write('{"flag":1}')
				self.set_secure_cookie('cookie_email',self.get_argument('email'))
			else:
				self.write('{"flag":0}')
		else:
			self.write('{"flag":0}')
class Register(BaseHandler):
	def get(self):
		sql_orm.query_user()
		self.render('register.html',page_title='register')
	def post(self):
		email = self.get_argument('email')
		psw = self.get_argument('psw')
		# if 