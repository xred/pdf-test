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
  constructor:->
    super
    am = new Suzaku.ApiManager
    am.setPath ""
    tm = new Suzaku.TemplateManager
    tm.setPath "templates/"
    tm.use "full-comment-item","rect-mark"
    tm.start (tpls)=>
      window.tpls = tpls
      @start()
  start:->
    @pages = []
    for p in pages = $(".page")
      @pages.push(new Page(this,p))
    @rightSection = new RightSection this
    $("#new-comment").on "click",=>
      @newComment()
  newComment:()->
    @emit "newComment"
  confirmNewComment:(page)->
    @emit "newComment:confirm"
    page.confirmNewComment()
    success = (content)=>
      page.completeNewComment()
      @addNewComment page,content
    fail = =>
      page.completeNewComment()
    @rightSection.initEditPage null,success,fail
  addNewComment:(targetPage,content)->
    #add comment
    console.log "new comment page:",targetPage,"content:",content
    targetPage.initUserMarks()
  initUserMarks:->
    for page in @pages
      page.initUserMarks

class RightSection extends Suzaku.Widget
  constructor:(app)->
    super "#right-section"
    for i in [1..5]
      item = new FullCommentItem()
      item.appendTo @UI['comments-wrapper']
    @initCommentPage()
  initCommentPage:->
    @UI['edit-page'].J.hide()
    @UI['comment-page'].J.fadeIn "fast"
  initEditPage:(inputData,success,fail)->
    @UI['edit-page'].J.fadeIn "fast"
    @UI['comment-page'].J.hide()
    CKEDITOR.instances.editPageEditor.setData(inputData)
    @UI['edit-accept-btn'].onclick = =>
      content = CKEDITOR.instances.editPageEditor.getData()
      success content
      @initCommentPage()
    @UI['edit-cancel-btn'].onclick = =>
      fail()
      @initCommentPage()
        
class FullCommentItem extends Suzaku.Widget
  constructor:(data)->
    super window.tpls['full-comment-item']

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
  clearListeners:->
    @dom.onmouseup = null
    @dom.onmousedown = null
    @dom.onmousemove = null
  newCommentActive:->
    @dom.onmousedown = (evt)=>
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
      @app.confirmNewComment this
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
  confirmNewComment:->
    action = "none"
    defaultInfo = @tempRectMark.getInfo()
    @tempRectMark.on "drag",(x,y)=>
      @mouseStartPos = x:x,y:y
      action = "drag"
    @tempRectMark.on "resize",(x,y)=>
      @mouseStartPos = x:x,y:y
      action = "resize"
    window.globalMouseListener.on "mouseup","confirmNewComment",(evt)=>
      return false if not @mouseStartPos
      action = "none"
      @mouseStartPos = null
      defaultInfo = @tempRectMark.getInfo()
    window.globalMouseListener.on "mousemove","confirmNewComment",(evt)=>
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
  completeNewComment:->
    window.globalMouseListener.off "mouseup","confirmNewComment"
    window.globalMouseListener.off "mousemove","confirmNewComment"
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



