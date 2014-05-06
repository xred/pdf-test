class RightSectionPage extends Suzaku.Widget
  animateRate = "normal"
  init:-> return true
  enterFromRight:->
    @emit "enter"
    @J.css {"z-index":9,left:"110%",display:"block"}
    @J.animate {left:"0"},animateRate
  enterFromLeft:->
    @emit "enter"
    @J.css {left:"-110%",display:"block"}
    @J.animate {left:"0"},animateRate,=>
      @J.css {"z-index":9}
  leaveToLeft:->
    @emit "leave"
    @J.css {"z-index":1,left:"0"}
    @J.animate {left:"-110%"},animateRate,=>@J.hide()
  leaveToRight:->
    @emit "leave"
    @J.css {left:"0"}
    @J.animate {left:"110%"},animateRate,=>
      @J.css {"z-index":1}
      @J.hide()

class EditPage extends RightSectionPage
  init:(type,inputData)->
    switch type
      when "newComment" then @UI['new-comment-options'].J.show()
      else @UI['new-comment-options'].J.hide()
    CKEDITOR.instances.editPageEditor.setData(inputData)
    
class SingleCommentPage extends RightSectionPage
  constructor:(target)->
    target.J.html window.tpls['single-comment-item']
    super target
  init:(commentData)->
    return null
            
class window.RightSection extends Suzaku.Widget
  constructor:(app)->
    super "#right-section"
    @app = app
    @pages = []
    @pageStack = []
    @init()
  init:->
    @commentPage = new RightSectionPage @UI['comment-page']
    @editPage = new EditPage @UI['edit-page']
    @singleCommentPage = new SingleCommentPage @UI['single-comment-page']
    @pages = [@commentPage,@editPage,@singleCommentPage]
    #init comments
    for i in [1..5]
      item = new CommentsItem this,[]
      item.appendTo @UI['comments-wrapper']
    @goInto @commentPage
  goInto:(page)->
    last = @pageStack[@pageStack.length - 1]
    if last then last.leaveToLeft()
    @pageStack.push page
    page.enterFromRight()
  goBack:->
    current = @pageStack.pop()
    if not current
      console.error "no page to go back"
      return false
    current.leaveToRight()
    @pageStack[@pageStack.length - 1].enterFromLeft()
  showNewCommentHint:->
    hintJ = @UI['new-comment-hint'].J
    contentJ = hintJ.find(".content")
    hintJ.show()
    contentJ.slideDown "fast"
    @UI['new-comment-cancel-btn'].onclick = =>
      @hideNewCommentHint()
      @app.newCommentCanceled()
  hideNewCommentHint:->
    hintJ = @UI['new-comment-hint'].J
    contentJ = hintJ.find(".content")
    contentJ.slideUp "fast",=>
      hintJ.hide()
  showEditPage:(type,inputData,success,fail)->
    @editPage.init type,inputData
    @UI['edit-accept-btn'].onclick = =>
      content = CKEDITOR.instances.editPageEditor.getData()
      success content
      @goBack()
    @UI['edit-cancel-btn'].onclick = =>
      fail()
      @goBack()
    @goInto @editPage
  showSingleComment:(commentData)->
    @singleCommentPage.init commentData
    @singleCommentPage.UI['back'].onclick = =>
      @goBack()
    @goInto @singleCommentPage
        
class CommentsItem extends Suzaku.Widget
  constructor:(rightSection,comments)->
    super window.tpls['comments-item']
    @rightSection = rightSection
    @comments = comments = [1..8]
    @toggleItems = []
    @unfoldBtn = null
    @folded = true
    if @comments.length > 3
      first = @addItem @comments[0]
      @insertUnfoldBtn first
      @addItem @comments[@comments.length - 1]
      @UI['fold'].onclick = => @fold()
    else
      for c in @comments
        @addItem c
  fold:->
    return false if @folded
    @UI['fold'].J.fadeOut "fast"
    @unfoldBtn.J.fadeIn "fast"
    for item,i in @toggleItems
      item.remove()
      @toggleItems[i] = null
    @toggleItems = []
    @folded = true
  unfold:->
    return false if not @folded
    @UI['fold'].J.fadeIn "fast"
    @unfoldBtn.J.hide()
    for c,i in @comments when i > 0 and i < (@comments.length - 1)
      item = @addItem c,true
      @toggleItems.push item
    @folded = false
  addItem:(data,animate = false)->
    item = new Suzaku.Widget @UI['single-comment-li-tpl'].J.html()
    item.data = data
    item.dom.onclick = => @rightSection.showSingleComment item.data
    item.appendTo @UI.list
    return item
  insertUnfoldBtn:(target)->
    item = new Suzaku.Widget @UI['unfold-btn-tpl'].J.html()
    item.dom.onclick = => @unfold()
    item.after target
    item.UI['num'].J.text @comments.length - 2
    @unfoldBtn = item
    
