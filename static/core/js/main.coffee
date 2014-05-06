console.log "run"
pdfUrl = null # use default pdf url for test

class GlobalMouseListener extends Suzaku.EventEmitter
  constructor:->
    super
    @unbindEvents()
  bindEvents:->
    document.body.onmousemove = (evt)=>
      @emit "mousemove",evt
    document.body.onmouseup = (evt)=>
      @emit "mouseup",evt
    document.body.onmousedown = (evt)=>
      @emit "mousedown",evt
  unbindEvents:->
    document.body.onmousemove = null
    document.body.onmouseup = null
    document.body.onmousedown = null
  on:->
    if not document.body.onmousemove
      @bindEvents()
    super
  off:->
    super
    if Object.keys(@_events).length is 0
      @unbindEvents()

class App extends Suzaku.EventEmitter
  newCommentLock = false
  constructor:->
    super
    am = new Suzaku.ApiManager
    am.setPath ""
    tm = new Suzaku.TemplateManager
    tm.setPath "/core/templates/"
    tm.use "comments-item","rect-mark","single-comment-item"
    tm.start (tpls)=>
      window.tpls = tpls
      @start()
  start:->
    @pages = []
    for p in pages = $(".page")
      @pages.push(new Page(this,p))
    @rightSection = new RightSection this
    $("#newComment").on "click",=>
      return false if newCommentLock
      $("#newComment").addClass "toggled"
      @newComment()
  newComment:()->
    newCommentLock = true
    @emit "newComment"
    @rightSection.showNewCommentHint()
  newCommentConfirm:(page)->
    @emit "newComment:confirm"
    page.newCommentConfirm()
    success = (content)=>
      console.log content
      if content.replace(" ","").length is "0"
        alert "Error: Content is Empty"
      @newCommentSuccessed page,content
    fail = =>
      @newCommentCanceled page
    @rightSection.hideNewCommentHint()
    @rightSection.showEditPage "newComment",null,success,fail
  newCommentSuccessed:(page,content)->
    newCommentLock = false
    page.newCommentCompleted()
    $("#newComment").removeClass "toggled"
    console.log "new comment page:",targetPage,"content:",content
    targetPage.initUserMarks()
  newCommentCanceled:(page)->
    newCommentLock = false
    if page then page.newCommentCompleted()
    else for p in @pages
      p.newCommentCompleted()
    $("#newComment").removeClass "toggled"
  initUserMarks:->
    for page in @pages
      page.initUserMarks

class RectMark extends Suzaku.Widget
  constructor:(type="normal")->
    super window.tpls['rect-mark']
    if type is "temp"
      @tempType()
  tempType:->
    @J.addClass "temp"
    @dom.onmousedown = (evt)=>
      @emit "drag",evt.clientX,evt.clientY
    @UI['resizer'].onmousedown = (evt)=>
      evt.stopPropagation()
      evt.preventDefault()
      @emit "resize",evt.clientX,evt.clientY
  getInfo:->
    obj = 
      left:@dom.offsetLeft
      top:@dom.offsetTop
      width:@dom.offsetWidth
      height:@dom.offsetHeight
    return obj
  
class Page extends Suzaku.Widget
  constructor:(app,pageContainerDom)->
    super pageContainerDom
    id = @dom.id.replace "pageContainer",""
    @markingWrapper = new Suzaku.Widget "<div class='marking-wrapper'></div>"
    @markingWrapper.appendTo @dom
    @textLayerJ = @J.find('.textLayer')
    @marks = []
    @app = app
    app.on "newComment",=>
      @newCommentActive()
    app.on "newComment:confirm",=>
      @clearListeners()
    app.on "newComment:active",(page)=>
      if page isnt this
        @clearListeners()
  clearListeners:->
    @dom.onmouseup = null
    @dom.onmousedown = null
    @dom.onmousemove = null
  newCommentActive:->
    @dom.onmousedown = (evt)=>
      if @tempRectMark then return false
      @app.emit "newComment:active",this
      evt.preventDefault()
      @textLayerJ = @J.find('.textLayer')
      r = @textLayerJ[0].getBoundingClientRect()
      x = evt.clientX - r.left
      y = evt.clientY - r.top
      @mouseStartPos = x:x,y:y
      @tempRectMark = new RectMark("temp")
      @tempRectMark.J.css left:x,top:y
      @tempRectMark.appendTo @markingWrapper
    @dom.onmouseup = (evt)=>
      return false if not @mouseStartPos
      @mouseStartPos = null
      @clearListeners()
      @app.newCommentConfirm this
    @dom.onmousemove = (evt)=>
      return false if not @mouseStartPos
      r = @textLayerJ[0].getBoundingClientRect()
      x = evt.clientX - r.left
      y = evt.clientY - r.top
      sp = @mouseStartPos
      if y < sp.y then top = y
      else top = sp.y
      if x < sp.x then left = x
      else left = sp.x
      width = Math.abs(x - sp.x)
      height = Math.abs(y - sp.y)
      @tempRectMark.J.css left:left,top:top,width:width,height:height
  newCommentConfirm:->
    action = "none"
    defaultInfo = @tempRectMark.getInfo()
    @tempRectMark.on "drag",(x,y)=>
      @mouseStartPos = x:x,y:y
      action = "drag"
    @tempRectMark.on "resize",(x,y)=>
      @mouseStartPos = x:x,y:y
      action = "resize"
    window.globalMouseListener.on "mouseup","newCommentConfirm",(evt)=>
      return false if not @mouseStartPos
      action = "none"
      @mouseStartPos = null
      defaultInfo = @tempRectMark.getInfo()
    window.globalMouseListener.on "mousemove","newCommentConfirm",(evt)=>
      return false if not @mouseStartPos
      dx = evt.clientX - @mouseStartPos.x
      dy = evt.clientY - @mouseStartPos.y
      switch action
        when "drag"
          @tempRectMark.J.css left:(defaultInfo.left + dx),top:(defaultInfo.top + dy)
        when "resize"
          width = (defaultInfo.width + dx)
          height = (defaultInfo.height + dy)
          if width < 5 then width = 5
          if height < 5 then height = 5
          @tempRectMark.J.css width:width,height:height
        else console.log "error status",action
  newCommentCompleted:->
    return false if not @tempRectMark
    window.globalMouseListener.off "mouseup","newCommentConfirm"
    window.globalMouseListener.off "mousemove","newCommentConfirm"
    @tempRectMark.remove()
    @tempRectMark = null
  initUserMarks:(marks)->
    "show user marks"
    return true
      
RunPDFViewer pdfUrl,=>
  window.globalMouseListener = new GlobalMouseListener()
  new App()
  ckConfig = height:400
  CKEDITOR.replace "editPageEditor",ckConfig



