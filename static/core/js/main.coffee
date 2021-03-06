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

window.showMessage = (content,type="normal")->
  msg = new Suzaku.Widget "<div class='message'><span>#{content}</span></div>"
  if type is "error" or type is "e"
    new Suzaku.Widget("<b class='error'>ERROR : </b>").insertTo(msg)
  msg.J.hide()
  msg.appendTo $("#global-message-container")
  msg.J.slideDown "fast"
  window.setTimeout (->
    msg.J.slideUp "slow",-> msg.J.remove()
    ),5000

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
    am.declare "getReplys","/reply",["commentid"]
    am.setMethod "post"
    am.declare "addComment","/comment",["action=add","aid=#{@aid}","content","markdata"]
    am.declare "addCommentToMark","/comment",["action=add","aid=#{@aid}","content","markid"]
    am.declare "addReply","/reply",['action=add','commentid',"content"]
    am.declare "voteupComment","/comment",["action=voteup","commentid"]
    am.declare "votedownComment","/comment",["action=votedown","commentid"]
    am.setErrorHandler "all",=>
      window.showMessage "Network error","e"
    @api = am.generate()
    tm = new Suzaku.TemplateManager
    tm.setPath "/core/templates/"
    tm.use "comments-item","rect-mark","single-comment-item"
    tm.start (tpls)=>
      window.tpls = tpls
      @start()
  start:->
    @initComments =>
      window.showMessage "User comments loaded successfully."
      @pages = []
      for p in pages = $(".page")
        @pages.push(new Page(this,p))
      @rightSection = new RightSection this
      $("#newComment").on "click",=>
        return false if newCommentLock
        $("#newComment").addClass "active"
        @showMarks()
        @newComment()
      $("#hideMarks").on "click",=>
        if not @showMarks() then @hideMarks()
      $("#scaleSelect").on "change",=> @handleResize()
      $("#zoomIn,#zoomOut").on "click",=> @handleResize()
      window.onresize = => @handleResize()
  handleResize:->
    for p in @pages
      p.onresize()
  showMarks:->
    if not $(".marking-wrapper").hasClass "hide"
      return false
    $(".marking-wrapper").removeClass "hide"
    $("#hideMarks").removeClass "active"
  hideMarks:->
    if $(".marking-wrapper").hasClass "hide"
      return false
    $(".marking-wrapper").addClass "hide"
    $("#hideMarks").addClass "active"
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
      window.showMessage "Cannot get comments","e"
  newComment:()->
    newCommentLock = true
    $(".rectMark").removeClass("focus").addClass("unselectable")
    @emit "newComment"
    @rightSection.showNewCommentHint()
  newCommentConfirm:(page)->
    @emit "newComment:confirm"
    page.newCommentConfirm()
    editPage = null
    success = (content)=>
      console.log content
      editPage.off "useColor"
      @newCommentSuccessed page,content
    fail = =>
      editPage.off "useColor"
      @newCommentCanceled page
    @rightSection.hideNewCommentHint()
    editPage = @rightSection.showEditPage "newComment",null,success,fail
    editPage.on "useColor",(color)=>
      page.tempRectMark.J.removeClass("color1 color2 color3 color4").addClass("color#{color}")
      page.tempRectMark.color = color
  newCommentSuccessed:(page,content)->
    newCommentLock = false
    markData = page.getTempMarkData()
    $("#newComment").removeClass "active"
    console.log "new comment page:",page,"content:",content
    page.newCommentCompleted()
    $(".rectMark").removeClass("unselectable")
    call = @api.addComment content,markData,(res)=>
      if not res.success
        window.showMessage res.error_msg,"error"
      markData.markid = res.markid
      window.showMessage "Comment and mark created successfully."
      @initComments =>
        @rightSection.initComments().resetStack().goInto @rightSection.commentPage
        @rightSection.scrollToMarkComments markData.markid
        page.initMarks()
        @scrollToRectMark markData
  newCommentCanceled:(page)->
    newCommentLock = false
    if page then page.newCommentCompleted()
    else for p in @pages
      p.newCommentCompleted()
    $("#newComment").removeClass "active"
    $(".rectMark").removeClass("unselectable")
  getPageById:(pageid)->
    res = page for page in @pages when parseInt(pageid) is parseInt(page.pageid)
    return res
  scrollToRectMark:(markData)->
    @showMarks()
    page = @getPageById markData.pageid
    markJ = $("#mark-#{markData.markid}")
    targetTop = page.dom.offsetTop + parseInt(markJ.css("top").replace("xp","")) - 30
    if not markJ.hasClass("focus")
      $(".rectMark").removeClass "focus"
    $("#viewerContainer").animate scrollTop:targetTop,"normal","swing",=>
      markJ.addClass "focus"
    return true

class RectMark extends Suzaku.Widget
  constructor:(type="normal",page,pageSize,data)->
    super window.tpls['rect-mark']
    if type is "temp"
      @tempType()
    else
      @page = page
      @data = data
      @id = data.markid
      @dom.id = "mark-#{@id}"
      @J.addClass "color#{data.markcolor}"
      @J.css color:data.markcolor
      @updateSize pageSize
      @dom.onclick = =>
        @active()
      @UI['dismiss'].onclick = (evt)=>
        evt.stopPropagation()
        @dismiss()
      @UI['undismiss'].onclick = (evt)=>
        evt.stopPropagation()
        @undismiss()
  active:->
    $("#comments-#{@id}").slideDown("fast")
    @page.markActive this
  undismiss:->
    if not @J.hasClass("dismiss") then return false
    @appendTo @J.parent().get(0)
    @J.removeClass("dismiss")
    @active()
  dismiss:->
    if @J.hasClass("dismiss") then return false
    @insertTo @J.parent().get(0)
    @J.addClass("dismiss").removeClass("focus")
    $("#comments-#{@id}").slideUp("fast")
  updateSize:(pageSize)->
    a = 100
    @J.css
      left:@data.markx * pageSize.width / a
      top:@data.marky * pageSize.height / a
      width:@data.markw * pageSize.width / a
      height:@data.markh * pageSize.height / a
  tempType:->
    @J.addClass "temp focus color1"
    @color = 1
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
      color:@color
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
  onresize:->
    @J = $("body ##{@dom.id}")
    @dom = @J.get(0)
    @markingWrapper.appendTo @dom
    pageSize = @getPageSize()
    m.updateSize pageSize for m in @marks
  getPageSize:->
    obj = 
      width:parseFloat(@J.css("width").replace("px",""))
      height:parseFloat(@J.css("height").replace("px",""))
    return obj
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
      data = @tempRectMark.getData()
      if data.width < 6 or data.height < 6
        @tempRectMark.remove()
        @tempRectMark = null
        @mouseStartPos = null
        return false
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
    pageSize = @getPageSize()
    a = 100
    obj =
      x:data.left/pageSize.width*a
      y:data.top/pageSize.height*a
      w:data.width/pageSize.width*a
      h:data.height/pageSize.height*a
      pageid:@pageid
      color:data.color
    return obj
  newCommentCompleted:->
    return false if not @tempRectMark
    window.globalMouseListener.off "mouseup","newCommentConfirm"
    window.globalMouseListener.off "mousemove","newCommentConfirm"
    @tempRectMark.remove()
    @tempRectMark = null
  initMarks:()->
    m.remove() for m in @marks
    @marks = []
    pageSize = @getPageSize()
    for m in @app.marks when m.pageid is @pageid
      @marks.push @addMark pageSize,m
    return true
  addMark:(pageSize,markData)->
    item = new RectMark "normal",this,pageSize,markData
    item.appendTo @markingWrapper
    return item
  markActive:(item)->
    $(".rectMark").removeClass("focus")
    item.J.addClass("focus")
    @app.rightSection.scrollToMarkComments item.data.markid
      
RunPDFViewer pdfUrl,=>
  window.globalMouseListener = new GlobalMouseListener()
  new App()
  ckConfig = height:180
  CKEDITOR.replace "editPageEditor",ckConfig



