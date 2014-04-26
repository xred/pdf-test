console.log "run"
pdfUrl = null # use default pdf url for test

class App extends Suzaku.EventEmitter
  constructor:->
    super
    am = new Suzaku.ApiManager
    am.setPath ""
    tm = new Suzaku.TemplateManager
    tm.setPath "templates/"
    tm.use "full-comment-item"
    tm.start (tpls)=>
      window.tpls = tpls
      @start()
  start:->
    @pages = []
    for p in pages = $(".page")
      @pages.push(new Page(this,p))
    @rightSection = new RightSection()
    $("#new-comment").on "click",=>
      @emit "newComment"

class RightSection extends Suzaku.Widget
  constructor:()->
    super "#right-section"
    for i in [1..5]
      item = new FullCommentItem()
      item.appendTo @UI['comments-wrapper']
        
class FullCommentItem extends Suzaku.Widget
  constructor:(data)->
    super window.tpls['full-comment-item']
  
class Page extends Suzaku.Widget
  constructor:(app,pageContainerDom)->
    super pageContainerDom
    id = @dom.id.replace "pageContainer",""
    @markingWrapper = new Suzaku.Widget "<div class='marking-wrapper'></div>"
    @markingWrapper.appendTo @dom
    @textLayerJ = @J.find('.textLayer')
    @marks = []
    app.on "newComment",=>
      @newCommentActive()
    app.on "newCommentCompleted",=>
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
      @tempRectMark = new Suzaku.Widget("<div class='tempRectMark rectMark'></div>")
      @tempRectMark.J.css left:x,top:y
      @tempRectMark.appendTo @markingWrapper
    @dom.onmouseup = (evt)=>
      return false if not @mouseStartPos
      @mouseStartPos = null
      @clearListeners()
      @confirmNewComment()
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
      
RunPDFViewer pdfUrl,=>
  new App()



