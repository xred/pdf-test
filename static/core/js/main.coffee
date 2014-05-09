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
    @marks = []
    @comments = []
    @aid = window.pdfDocument.fingerprint
    am = new Suzaku.ApiManager
    am.setPath "/pdfview/"
    am.setMethod "get"
    am.declare "getComments","/comment",["aid=#{@aid}"]
    am.setMethod "post"
    am.declare "addComment","/comment",["action=add","aid=#{@aid}","content","markdata"]
    am.declare "addCommentToMark","/comment",["action=add","aid=#{@aid}","content","markid"]
    @api = am.generate()
    tm = new Suzaku.TemplateManager
    tm.setPath "/core/templates/"
    tm.use "comments-item","rect-mark","single-comment-item"
    tm.start (tpls)=>
      window.tpls = tpls
      @start()
  start:->
    @initComments =>
      @pages = []
      for p in pages = $(".page")
        @pages.push(new Page(this,p))
      @rightSection = new RightSection this
      $("#newComment").on "click",=>
        return false if newCommentLock
        $("#newComment").addClass "toggled"
        @newComment()
  initComments:(callback)->
    call = @api.getComments (res)=>
      if res.success
        @comments = res.comments
        @marks = res.marks
        #merge comments
        for m in @marks
          m.comments = []
          for c in @comments when c.markid is m.markid
            m.comments.push c
      callback() if callback
    call.fail =>
      console.error "cannot get comments",arguments
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
    markData = page.getTempMarkData()
    $("#newComment").removeClass "toggled"
    console.log "new comment page:",page,"content:",content
    page.newCommentCompleted()
    call = @api.addComment content,markData,(res)=>
      if not res.success
        console.error res.error_msg
      @initComments =>
        @rightSection.initComments().resetStack().goInto @rightSection.commentPage
        page.initMarks()
  newCommentCanceled:(page)->
    newCommentLock = false
    if page then page.newCommentCompleted()
    else for p in @pages
      p.newCommentCompleted()
    $("#newComment").removeClass "toggled"

class RectMark extends Suzaku.Widget
  constructor:(type="normal",data)->
    super window.tpls['rect-mark']
    if type is "temp"
      @tempType()
    else
      @J.css
        left:data.markx
        top:data.marky
        width:data.markw
        height:data.markh
        color:data.markcolor
  tempType:->
    @J.addClass "temp"
    @dom.onmousedown = (evt)=>
      @emit "drag",evt.clientX,evt.clientY
    @UI['resizer'].onmousedown = (evt)=>
      evt.stopPropagation()
      evt.preventDefault()
      @emit "resize",evt.clientX,evt.clientY
  getData:->
    obj = 
      left:@dom.offsetLeft
      top:@dom.offsetTop
      width:@dom.offsetWidth
      height:@dom.offsetHeight
    return obj
  
class Page extends Suzaku.Widget
  constructor:(app,pageContainerDom)->
    super pageContainerDom
    @pageid = parseInt(@dom.id.replace "pageContainer","")
    @markingWrapper = new Suzaku.Widget "<div class='marking-wrapper'></div>"
    @markingWrapper.appendTo @dom
    @textLayerJ = @J.find('.textLayer')
    @app = app
    @marks = []
    @initMarks()
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
    defaultData = @tempRectMark.getData()
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
      defaultData = @tempRectMark.getData()
    window.globalMouseListener.on "mousemove","newCommentConfirm",(evt)=>
      return false if not @mouseStartPos
      dx = evt.clientX - @mouseStartPos.x
      dy = evt.clientY - @mouseStartPos.y
      switch action
        when "drag"
          @tempRectMark.J.css left:(defaultData.left + dx),top:(defaultData.top + dy)
        when "resize"
          width = (defaultData.width + dx)
          height = (defaultData.height + dy)
          if width < 5 then width = 5
          if height < 5 then height = 5
          @tempRectMark.J.css width:width,height:height
        else console.log "error status",action
  getTempMarkData:->
    data = @tempRectMark.getData()
    obj =
      x:data.left
      y:data.top
      w:data.width
      h:data.height
      pageid:@pageid
      color:1
    return obj
  newCommentCompleted:->
    return false if not @tempRectMark
    window.globalMouseListener.off "mouseup","newCommentConfirm"
    window.globalMouseListener.off "mousemove","newCommentConfirm"
    @tempRectMark.remove()
    @tempRectMark = null
  initMarks:()->
    console.log "fuck"
    m.remove() for m in @marks
    @marks = []
    for m in @app.marks when m.pageid is @pageid
      @marks.push @addMark m
    return true
  addMark:(markData)->
    item = new RectMark "normal",markData
    item.markData = markData
    item.appendTo @markingWrapper
    item.dom.onclick = =>
      console.log "click",item
      @app.rightSection.scrollToMarkComments item.markData,item
    return item
      
RunPDFViewer pdfUrl,=>
  window.globalMouseListener = new GlobalMouseListener()
  new App()
  ckConfig = height:400
  CKEDITOR.replace "editPageEditor",ckConfig



