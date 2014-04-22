console.log "run"
pdfUrl = null # use default pdf url for test

class App extends Suzaku.EventEmitter
  constructor:->
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
      @pages.push(new Page(p))
    @rightSection = new RightSection()


class RightSection extends Suzaku.Widget
  constructor:()->
    super "#right-section"
    for i in [1..5]
      item = new FullCommentItem()
      console.log item
      console.log @UI['comments-wrapper']
      item.appendTo @UI['comments-wrapper']
        
class FullCommentItem extends Suzaku.Widget
  constructor:(data)->
    super window.tpls['full-comment-item']

class Page extends Suzaku.Widget
  constructor:(pageContainerDom)->
    super pageContainerDom
    id = @dom.id.replace "pageContainer",""
    @initInteraction()
  initInteraction:->
    @dom.onmousedown = =>
    @dom.onmouseup = =>
    @dom.onmousemove = =>
      
RunPDFViewer pdfUrl,=>
  new App()


