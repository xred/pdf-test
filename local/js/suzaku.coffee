if not $
  console.warn "cannot find JQuery!  -- Suzaku"
debug = false
  
class Suzaku
  constructor:()->
    console.log "init Suzaku" if debug
    @Widget = Widget
    @TemplateManager = TemplateManager
    @EventEmitter = EventEmitter
    @AjaxManager = AjaxManager
    @ApiManager = ApiManager
    
    @KeyboardManager = KeyboardManager
    @AnimationManager = null
    @Utils = null
    @Key = null
    @Mouse = null
    @WsServer = null
  debug:->
    debug = true

class EventEmitter
  constructor:()->
    @_events = {}
  on:(event,labels,callback)->
    #labels is string. splited by space
    if not callback
      callback = labels
      labels = null
    @_events[event] = [] if not @_events[event]
    e = callback:callback,labels:if labels then labels.split(" ") else null
    @_events[event].push e
    return e
  once:(event,callback)->
    if not callback
      return console.error "need a callback！ --Suzaku.EventEmitter"
    e = null
    f = =>
      @off event,e
      callback.apply this,arguments
    e = @on event,f
    return e
  off:(event,target)->
    if not @_events[event]
      console.warn "no events named #{event} --Suzaku.EventEmitter"
      return false
    type = typeof target
    switch type
      when "object"
        for e in @_events[event] when e is target
          Utils.removeItem @_events[event],e
          if @_events[event].length is 0 then delete @_events[event]
          return true
        console.error "cannot find event #{target} of #{event}-- Suzaku.EventEmitter"
      when "string"
        remains = []
        for e in @_events[event]
          found = false
          for l in e.labels when l is target
            found = true
            break
          if not found then remains.push e
        @_events[event] = remains
        if @_events[event].length is 0 then delete @_events[event]
      else
        for e in @_events[event]
          e = null
        delete @_events[event]
    return true
  emit:(event)->
    return false if !@_events[event]
    for e in @_events[event]
      func = e.callback
      continue if typeof func isnt "function"
      func.apply this,Array.prototype.slice.call arguments,1
      
class Widget extends EventEmitter
  constructor:(creator)->
    super()
    if not creator
      console.error "need a creator! -- Suzaku.Widget"
      return
    @J = null
    @dom = null
    @template = null
    @creator = creator
    @UI = {}
    if typeof creator is 'string'
      if creator.indexOf("<")> -1 and creator.indexOf(">")>-1
        template = creator
        if creator.indexOf("<tr ") > -1
          tempDiv = document.createElement "table"
        else
          tempDiv = document.createElement "div"
        tempDiv.innerHTML = template
        @dom = tempDiv.children[0]
        @J = $ @dom if $
      else
        @J = $ creator if $
        @dom = document.querySelector creator
        if not @dom
          console.error "Wrong selector!: '#{creator}' cannot find element by this -- Suzaku.Widget"
          return
    if $ and creator instanceof $
      @J = creator
      @dom = @J[0]
    if creator instanceof window.HTMLElement or typeof creator.appendChild is "function"
      @dom = creator
      @J = $ @dom if $
    @initUI()
  _initUI:(targetDom)->
    return false if not targetDom.children
    for dom in targetDom.children
      if dom.children and dom.children.length > 0
        @_initUI dom
      did = dom.getAttribute "data-id"
      if not did then continue
      J = if $ then $(dom) else null
      @UI[did] = dom
      @UI["$#{did}"] = J
      @UI["#{did}$"] = J
      dom.dom = dom
      dom.J = J
  initUI:()->
    @UI = {}
    @_initUI @dom
  remove:()->
    parent = @dom.parentElement or @dom.parentNode
    parent.removeChild @dom if parent
    for name,d of @UI
      delete @UI[name]
    @dom = null
    @J = null
  css3Animate:(animateClass,waitTime,callback)->
    @J.addClass animateClass
    if not waitTime or typeof waitTime is "function"
      callback = waitTime
      s = window.getComputedStyle @dom
      waitTime = s.webkitAnimationDuration or s.animationDuration or ".5s"
      waitTime = parseInt((waitTime.replace("s",""))*1000+30)
    window.setTimeout (=>
      @J.removeClass animateClass if @J
      callback.call this if callback
      ),waitTime
  before:(target)->
    if target.dom instanceof HTMLElement
      target = target.dom
    if $ and target instanceof $
      target = target[0]
    if target instanceof HTMLElement
      target.parentElement.insertBefore @dom,target
    else
      console.error "invaild target!  --Suzaku.Widget"
  after:(target)->
    if target instanceof Widget
      target = target.dom
    if $ and target instanceof $
      target = target[0]
    if target instanceof HTMLElement
      parent = target.parentElement
      next = null
      for dom,index in parent.children 
        if dom is target and index < parent.children.length - 1
          next = parent.children[index+1]
      if next then parent.insertBefore @dom,next
      else parent.appendChild @dom
    else
      console.error "invaild target!  --Suzaku.Widget"
  replace:(target)->
    @before target
    if target instanceof Widget then target.remove()
    if $ and target instanceof $ then target.remove()
    parent = target.parentElement or target.parentNode
    if target instanceof HTMLElement then parent.removeChild target
  appendTo:(target)->
    console.error "need a target --Suzaku.Widget",target if not target
    if target instanceof Widget or target.dom instanceof window.HTMLElement
      target.dom.appendChild @dom
      return this
    if $ and target instanceof $
      target.append @dom
      return this
    if typeof target.appendChild is "function"
      target.appendChild @dom
      return this
  insertTo:(target)->
    console.error "need a target --Suzaku.Widget",target if not target
    fec = target.firstElementChild
    if target.dom instanceof window.HTMLElement
      fec = target.dom.firstElementChild
    if $ and target instanceof $
      fec = target.get(0).firstElementChild
    if not fec then return @appendTo target
    else @before fec
    return this
          
class TemplateManager extends EventEmitter
  constructor:()->
    super();
    @tplPath = "./templates/"
    @templates = {}
    @tplNames = []
  use:()->
    for item in arguments
      @tplNames.push item
  setPath:(path)->
    if typeof path isnt "string"
      return console.error "Illegal Path: #{path} --Suzaku.ApiManager"
    arr = path.split ''
    if arr[arr.length-1] isnt "/"
      arr.push "/"
    path = arr.join ''
    console.log 'set template file path:',path if debug
    @tplPath = path
  start:(callback)->
    if typeof callback is "function"
      @on "load",=>
        callback @templates
    ajaxManager = new AjaxManager
    localDir = @tplPath
    for name in @tplNames
      url = if name.indexOf(".html")>-1 then localDir+name else localDir+name+".html"
      req = ajaxManager.addGetRequest url,null,(data,textStatus,req)=>
        @templates[req.Suzaku_tplName] = data
      req.Suzaku_tplName = name
    ajaxManager.start =>
      console.log "template loaded" if debug
      @emit "load",@templates

class AjaxManager extends EventEmitter
  constructor:()->
    return console.error "ajax Manager needs Jquery!" if not $
    super()
    @reqs = []
    @ajaxMissions = {}
    @tidCounter = 0
  addRequest:(option)->
    option.type = option.type or 'get'
    return console.error "ajax need url!" if not option.url
    console.log "Add request:",option.type,"to",option.url,"--Suzaku.AjaxManager" if debug
    option.externPort = {}
    @reqs.push option
    return option.externPort
  addGetRequest:(url,data,success,dataType)->
    return @addRequest
      type:"get"
      url:url
      data:data
      dataType:dataType
      retry:5
      success:success
  addPostRequest:(url,data,success,dataType)->
    return @addRequest
      type:"post"
      url:url
      data:data
      retry:5
      dataType:dataType
      success:success
  start:(callback)->
    id = @tidCounter += 1
    newAjaxTask = 
      id:id
      reqs:@reqs
      finishedNum:0
      callback:callback
    @ajaxMissions[id] = newAjaxTask
    console.log "start request tasks",newAjaxTask if debug
    @reqs = []
    ajaxManager = this
    for taskOpt,index in @ajaxMissions[id].reqs
      JAjaxReqOpt = Utils.clone taskOpt
      delete JAjaxReqOpt.retry
      delete JAjaxReqOpt.externPort
      JAjaxReqOpt.success = (data,textStatus,req)=>
        @_ajaxSuccess.apply this,arguments
      JAjaxReqOpt.error = (req,textStatus,error)=>
        @_ajaxError.apply this,arguments
        
      ajaxReq = $.ajax JAjaxReqOpt
      ajaxReq.Suzaku_JAjaxReqOpt = JAjaxReqOpt #Suzaku_JAjaxReqOpt is option for Jquery ajax request
      ajaxReq.Suzaku_taskOpt = taskOpt #Suzaku_taskOpt is option added by Suzaku_ajaxManager
      ajaxReq.Suzaku_ajaxMission = newAjaxTask #Suzaku_ajaxMission is 
      ajaxReq[name] = value for name,value of taskOpt.externPort
      #console.log ajaxReq
      
    @on "finish",(taskId)=>
      callback = @ajaxMissions[taskId].callback
      delete @ajaxMissions[taskId]
      callback() if typeof callback is "function"
      
  _ajaxSuccess:(data,textStatus,req)->
    #console.log "ajax surceess",data if debug
    ajaxMission =  req.Suzaku_ajaxMission
    ajaxMission.finishedNum += 1
    req.Suzaku_taskOpt.success data,textStatus,req if req.Suzaku_taskOpt.success
    if ajaxMission.finishedNum is ajaxMission.reqs.length
      console.log "finish",this if debug
      @emit "finish",ajaxMission.id
        
  _ajaxError:(req,textStatus,error)->
    console.log "ajax error",error if debug
    taskOpt = req.Suzaku_taskOpt
    retry = taskOpt.retry
    retry = 5 if not retry
    retried = req.Suzaku_retried or 0
    if retried < retry
      ajaxReq = $.ajax req.Suzaku_JAjaxReqOpt
      ajaxReq.Suzaku_JAjaxReqOpt = req.Suzaku_JAjaxReqOpt
      ajaxReq.Suzaku_taskOpt = req.Suzaku_taskOpt
      ajaxReq.Suzaku_ajaxMission = req.Suzaku_ajaxMission
      ajaxReq[name] = value for name,value of req.Suzaku_taskOpt.externPort
      ajaxReq.Suzaku_retried = retried + 1
    else
      ajaxMission = req.Suzaku_ajaxMission
      ajaxMission.finishedNum += 1
      console.error "request failed!",req,textStatus,error
      req.Suzaku_taskOpt.fail req,textStatus,error if req.Suzaku_taskOpt.fail
      if ajaxMission.finishedNum is ajaxMission.reqs.length
        @emit "finish",ajaxMission.id
        
class Api extends EventEmitter
  constructor:(name,params,JAjaxOptions,url,method,errorHandlers)->
    super()
    if not params or not (params instanceof Array)
      return console.error "Illegel arguments #{name} #{params}! --Suzaku.ApiGenerator"
    @name = name
    @url = url
    @method = method
    @params = []
    @errorHandlers = errorHandlers
    @JAjaxOptions = JAjaxOptions
    #console.log @name if debug
    @_initParams(params)
  _initParams:(params)->
    for param in params
      if param.indexOf('=') > -1
        arr = param.split('=')
        name = arr[0]
        value = arr[1]
        @params.push
          name:name.replace('?','')
          value:value
      else
        arr = param.split ":"
        name = arr[0]
        type = arr[1] or "any"
        @params.push
          force:if param.indexOf('?')>-1 then false else true
          name:name.replace('?','')
          type:type.replace('?','').split('/')
  _checkParams:->
    return true
  send:->
    return false if not @_checkParams()
    data = {suzaku_random:Math.random()}
    argIndex = 0
    successCallback
    lastArg = arguments[arguments.length - 1]
    if typeof lastArg is "function"
      successCallback = lastArg
      arguments[arguments.length - 1] = null
    for param,index in @params
      if param.value
        data[param.name] = param.value
      else
        arg = arguments[argIndex]
        if arg is undefined or arg is null then noarg = true
        else noarg = false
        if not param.force and noarg then continue
        if param.force and noarg
          console.warn "api #{@name} has different args from declare:",arg
        data[param.name] = arg
        argIndex += 1
    console.log "api #{@method} #{@name} send data:",data if debug
    if @method is "post" and typeof data is "object"
      data = JSON.stringify data
      dataType = "text"
    opt =
      type:@method
      url:@url
      dataType:dataType or "json"
      data:data
      success:(data,textStatus,req)=>
        if typeof data is "string"
          try
            data = JSON.parse data
        @onsuccess data if typeof @onsuccess is "function"
        @onsuccess = null
        evtData =
          successed:true
          data:data
          textStatus:textStatus
          JAjaxReq:req
        @emit "success",evtData
        @emit "finish",evtData
      error:(req,textStatus,error)=>
        console.error "Api ajax error:#{error} --Suzaku.API"
        console.warn arguments
        @onfail error,textStatus if typeof @onfail is "function"
        @onfail = null
        @errorHandlers.requestFail() if @errorHandlers.requestFail
        if @errorHandlers[req.status]
          @errorHandlers[req.status]()
        evtData =
          successed:false
          JAjaxReq:req
          textStatus:textStatus
          errorCode:req.status
          error:error
        @emit "error",evtData
        @emit "finish",evtData
    for name,value of @JAjaxOptions
      opt[name] = value
    @request = $.ajax opt
    if successCallback then @success successCallback
  respond:(callback)->
    return @success callback
  success:(callback)->
    @onsuccess = callback
    return this
  complete:(callback)->
    @request.complete callback
    return this
  fail:(callback)->
    @onfail = callback
    return this
    
class ApiManager extends EventEmitter
  constructor:()->
    super()
    @apis = {}                 #Api data structure saved here
    @errorHandlers = {}
    @method = "get"
    @path = ""
  setPath:(path)->
    if typeof path isnt "string"
      return console.error "Illegal Path: #{path} --Suzaku.ApiManager"
    arr = path.split ''
    if arr[arr.length-1] is "/"
      arr[arr.length-1] = ""
    path = arr.join ''
    console.log path if debug 
    @path = path
  setMethod:(method)->
    if method isnt "get" and method isnt "post"
      return console.error "Illegal method #{method} --Suzaku.ApiManager"
    @method = method
  setErrorHandler:(errorCode,handler)->
    @errorHandlers[errorCode] = handler
  setRequestFailHandler:(handler)->
    @errorHandlers.requestFail = handler
  declare:()->
    name = arguments[0]
    if typeof arguments[1] is "string"
      url = arguments[1]
      if url.indexOf('/') is 0 then url = url.slice(1)
      params = arguments[2] or []
      JAjaxOptions = arguments[3] or {}
    else
      url = name
      params = arguments[1] or []
      JAjaxOptions = arguments[2] or {}
    newApi= new Api name,params,JAjaxOptions,"#{@path}/#{url}",@method,@errorHandlers
    @apis[name] = newApi
  generate:()->
    apiObj = {}
    for name,api of @apis
      apiObj[name] = @_generate api
    @apis = {}
    return apiObj
  _generate:(api)->
    return ()->
      api.send.apply api,arguments
      return api

class KeyboardManager extends EventEmitter
  constructor:->
    super
    @pushedKey = {}
    window.onkeydown = (evt)=>
      for name,keyCode of window.Suzaku.Key
        if evt.keyCode is keyCode
          @pushedKey[name] = true
          return @emit "keyDown",name
      @emit "keyDown","unknow"
    window.onkeyup = (evt)=>
      for name,keyCode of window.Suzaku.Key
        if evt.keyCode is keyCode
          @pushedKey[name] = false
          return @emit "keyUp",name
      @emit "keyDown","unknow"
        
window.Suzaku = new Suzaku
window.Suzaku.Utils = Utils =
  getUrlArgument:(name)->
    url = window.location.href
    reg = new RegExp("(^|&|\\?)"+ name + "=([^&]*)(&|$)")
    if r = url.match(reg)
      return unescape(r[2])
    else return null 
  setTimeout:(time,callback)->
    return window.setTimeout callback,time
  setInterval:(time,callback)->
    return window.setInterval callback,time
  count:(obj)->
    return Object.keys(obj).length
  createQueue:(number,callback)->
    q = new EventEmitter()
    timer = 0
    q.next = ->
      @emit "next"
      timer += 1
      if timer >= number
        @emit "complete"
        callback() if callback
    return q
  random:->
    if arguments.length is 1
      if arguments[0] instanceof Array
        length = arguments[0].length
        index = Math.floor(Math.random() * length)
        return arguments[0][index]
      else return arguments[0]
    else
      length = arguments.length
      index = Math.floor(Math.random() * length)
      return arguments[index]
  localData:(action,name,value)->
    #action = "set,clear,get"
    switch action
      when "set","save"
        if value is undefined
          return console.error "no value to save."
        else
          window.localStorage.setItem name,JSON.stringify(value)
          return true
      when "get","read"
        v = window.localStorage.getItem name 
        if not v then return null
        try
          return JSON.parse(v)
        catch err
          return v
      when "clear","remove"
        window.localStorage.removeItem name
        return true
      else
        console.error "invailid localData action:#{action}"
  bindMobileClick:(dom,callback)->
    if not dom
      return console.error "no dom exist --Suzaku.bindMobileClick"
    if typeof callback isnt "function"
      console.error "callback need to be function --Suzaku.bindMobileClick"
      return
    if dom instanceof $
      J = dom
      J.on "touchend",(evt)->
        evt.stopPropagation()
        evt.preventDefault()
        J.off "mouseup"
        callback.call this,evt
      J.on "mouseup",(evt)->
        evt.stopPropagation()
        evt.preventDefault()
        J.off "touchend"
        callback.call this,evt
    else
      if dom.dom instanceof HTMLElement
        dom = dom.dom
      else
        if not (dom instanceof HTMLElement)
          console.error "invailid dom exist --Suzaku.bindMobileClick",dom if debug
          return 
      dom.ontouchend = (evt)->
        evt.stopPropagation()
        evt.preventDefault()
        dom.onmouseup = null
        callback.call this,evt
      dom.onmouseup = (evt)->
        evt.stopPropagation()
        evt.preventDefault()
        dom.ontouchend = null
        callback.call this,evt
  setLocalStorage:(obj)->
    for name,item of obj
      window.localStorage[name] = item
  free:()->
    for target in arguments
      continue if not target
      if target instanceof Array
        for i,index in target
          target[index] = null
      else if typeof target is "object"
        for name,item of target
          delete target[name]
  clone:(target,deepClone=false)->
    if target instanceof Array
      newArr = []
      for item,index in target
        newArr.push if deepClone then Utils.clone item,true else item
      return newArr
    if typeof target is 'object'
      newObj = {}
      for name,item of target
        newObj[name] = if deepClone then Utils.clone item,true else item
      return newObj
    return target
  compare:(a,b)->
    if a is b then return true
    if parseInt(a) is parseInt(b) then return true
    if Math.abs(parseFloat(a)-parseFloat(b)) < 0.0001 then return true
    return false
  generateId:(source)->
    if typeof source isnt "object"
      return console.log "type of source need to be Object --Suzaku.generateId"
    source.__idCounter = 0 if not source.__idCounter
    source.__idCounter += 1
    return source.__idCounter
  removeItemByIndex:(source,index)->
    if index < 0 or index > (source.length - 1)
      return console.error "invailid index:#{index} for source:",source
    return source.splice index,1
  removeItem:(source,target,value)->
    if source instanceof Array
      for item,index in source when item is target
        Utils.removeItemByIndex source,index
    else
      for name,item of source
        if target is item or (typeof target is "string" and item[target] is value)
          delete source[name]
  findItem:(source,key,value)->
    if typeof key is 'string' and value isnt undefined
      target = {}
      target[key] = value
    else target = key
    for name,item of source
      if Utils.compare(item,target) is true then return true
      if typeof target is "object"
        found = true
        for keyname,keyvalue of target
          if Utils.compare item[keyname],keyvalue
            continue
          else
            found = false
            break
        if found then return item
    return false
  sliceNumber:(number,afterDotNumber=2,force=false)->
    if isNaN number
      console.warn "NaN is not Number --Suzaku sliceNumber" if debug
      return 0
    afterDotNumber = parseInt afterDotNumber
    floatNumber = parseFloat number
    intNumber = parseInt number
    if not floatNumber and intNumber isnt 0
      return console.error "argument:#{number} is not number --Suzaku.sliceNumber"
    snumber = number.toString()
    dotIndex = snumber.indexOf('.')
    if dotIndex < 0
      if force
        s = ''
        s+='0' for index in [1..afterDotNumber]
        return "#{number}.#{s}"
      else
        return number
    else
      s = snumber.slice 0,dotIndex+afterDotNumber+1
      if force
        newDotIndex = s.indexOf '.'
        if s.length <= newDotIndex + afterDotNumber
          s += '0' for [0..(newDotIndex + afterDotNumber - s.length)]
      return s
  parseTime:(time,form,returnArr)->
    #keys = "Y","M","D","d","h","m","s"
    form = "Y年M月D日h点m分" if not form
    arr = form.split('')
    time = new Date time
    for value,index in arr
      switch value
        when "Y" then arr[index] = time.getFullYear()
        when "M" then arr[index] = time.getMonth()+1
        when "D" then arr[index] = time.getDate()
        when "d"
          switch parseInt time.getDay()
            when 1 then arr[index] = "一"
            when 2 then arr[index] = "二"
            when 3 then arr[index] = "三"            
            when 4 then arr[index] = "四"
            when 5 then arr[index] = "五"
            when 6 then arr[index] = "六"       
            when 0 then arr[index] = "日"     
        when "h"
          arr[index] = time.getHours().toString()
          if arr[index].length is 1 then arr[index] = "0"+arr[index]
        when "m" 
          arr[index] = time.getMinutes().toString()
          if arr[index].length is 1 then arr[index] = "0"+arr[index]
        when "s" 
          arr[index] = time.getSeconds().toString()
          if arr[index].length is 1 then arr[index] = "0"+arr[index]
    if returnArr then return arr
    else return arr.join ''
  checkBrowser:->
    u = navigator.userAgent
    app = navigator.appVersion;
    info = 
      trident: u.indexOf('Trident') > -1 #IE内核
      presto: u.indexOf('Presto') > -1 #opera内核
      webKit: u.indexOf('AppleWebKit') > -1 #苹果、谷歌内核
      gecko: u.indexOf('Gecko') > -1 && u.indexOf('KHTML') is -1#火狐内核
      mobile: (/AppleWebKit.*Mobile.*/).test(u) #是否为移动终端
      ios: (/\(i[^;]+;( U;)? CPU.+Mac OS X/).test(u) #ios终端
      android: u.indexOf('Android') > -1 || u.indexOf('Linux') > -1 #android终端或者uc浏览器
      iPhone: u.indexOf('iPhone') > -1 #是否为iPhone或者QQHD浏览器
      iPad: u.indexOf('iPad') > -1 #是否iPad
      webApp: u.indexOf('Safari') == -1 #是否web应该程序，没有头部与底部
    return info
  decodeHTML:(str)->
    return str if not str
    decodeDict = 
      "&lt;"  : "<"
      "&gt;"  : ">"
      "&amp;" : "&"
      "&nbsp;": " "
      "&quot;": "\""
      "&copy;": "©"
    for name,value of decodeDict
      r = new RegExp(name,"g")
      str = str.replace r,value
    return str

window.Suzaku.Key =
  0:48
  1:49
  2:50
  3:51
  4:52
  5:53
  6:54
  7:55
  8:56
  9:57
  a:65
  b:66
  c:67
  d:68
  e:69
  f:70
  g:71
  h:72
  i:73
  j:74
  k:75
  l:76
  m:77
  n:78
  o:79
  p:80
  q:81
  r:82
  s:83
  t:84
  u:85
  v:86
  w:87
  x:88
  y:89
  z:90
  space:32
  shift:16
  ctrl:17
  alt:18
  left:37
  right:39
  down:40
  up:38
  enter:13
  backspace:8
  escape:27
  del:46
  esc:27
  pageup:33
  pagedown:34
  tab:9
window.Suzaku.Mouse = 
  left:0
  middle:1
  right:2
