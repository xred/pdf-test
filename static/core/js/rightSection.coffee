class RightSectionPage extends Suzaku.Widget
  animateRate = "normal"
  init:-> return true
  enterFromRight:(callback)->
    @emit "enter"
    @J.css {left:"110%",display:"block"}
    @J.animate {left:"0"},animateRate,callback
  enterFromLeft:(callback)->
    @emit "enter"
    @J.css {left:"-110%",display:"block"}
    @J.animate {left:"0"},animateRate,callback
  leaveToLeft:->
    @emit "leave"
    @J.css {left:"0"}
    @J.animate {left:"-110%"},animateRate,=>
      @J.hide()
  leaveToRight:->
    @emit "leave"
    @J.css {left:"0"}
    @J.animate {left:"110%"},animateRate,=>
      @J.hide()

class EditPage extends RightSectionPage
  constructor:->
    super
    @J.find(".color-btn").on "click",->
      $(this).addClass("active").siblings().removeClass("active")
    @UI.color1.onclick = => @emit "useColor",1
    @UI.color2.onclick = => @emit "useColor",2
    @UI.color3.onclick = => @emit "useColor",3
    @UI.color4.onclick = => @emit "useColor",4
  init:(type,inputData)->
    @J.find('.header-section').hide()
    switch type
      when "newComment" then @UI['new-comment-options'].J.show()
      when "addComment" then @UI['add-comment-options'].J.show()
    CKEDITOR.instances.editPageEditor.setData(inputData)
    
class SingleCommentPage extends RightSectionPage
  constructor:(target,@rightSection)->
    target.J.html window.tpls['single-comment-item']
    super target
    @api = @rightSection.app.api
    @UI.back.onclick = (evt)=>
      evt.stopPropagation()
      @rightSection.goBack()
  init:(commentData,commentsItem)->
    @commentData = commentData
    @commentsItem = commentsItem
    @UI.nickname.J.text commentData.nickname
    @UI["vote-up-num"].J.text commentData.praisenum
    @UI['vote-up'].onclick = => @voteUpComment()
    @UI['vote-down'].onclick = => @voteDownComment()
    @UI['vote-down'].onclick = => @voteDownComment()
    @UI['reply'].onclick = => @addReply()
    @UI.content.J.html commentData.content
    for d in [1..5]
      item = new Suzaku.Widget @UI['single-reply-li-tpl'].J.html()
      item.appendTo @UI['reply-list']
    return null
  voteUpComment:->
    call = @api.voteupComment @commentData.commentid,(res)=>
      if not res.success
        return console.error res.error_msg
      @commentData.praisenum = res.praisenum
      @UI['vote-up-num'].J.text res.praisenum
      @commentsItem.updateVoteupNum @commentData.commentid,res.praisenum
    call.fail =>
      console.error arguments
  voteDownComment:->
    call = @api.votedownComment @commentData.commentid,(res)=>
      if not res.success
        return console.error res.error_msg
      @commentData.praisenum = res.praisenum
      @UI['vote-up-num'].J.text res.praisenum
      @commentsItem.updateVoteupNum @commentData.commentid,res.praisenum
    call.fail =>
      console.error arguments
  addReply:->
    console.log "add reply"
            
class window.RightSection extends Suzaku.Widget
  constructor:(app)->
    super "#right-section"
    @app = app
    @commentsItems = []
    @rightSectionPages = []
    @pageStack = []
    @init()
  init:->
    @commentPage = new RightSectionPage @UI['comment-page']
    self = this
    @editPage = new EditPage @UI['edit-page']
    @singleCommentPage = new SingleCommentPage @UI['single-comment-page'],this
    @rightSectionPages = [@commentPage,@editPage,@singleCommentPage]
    @initComments()
    @goInto @commentPage
  initComments:->
    i.remove() for i in @commentsItems
    @commentsItems = []
    for m in @app.marks
      item = new CommentsItem this,m.comments,m
      item.appendTo @UI['comments-wrapper']
      @commentsItems.push item
      @UI['comments-wrapper'].J.css "padding-bottom",window.screen.height
    return this
  scrollToMarkComments:(markid)->
    if @currentPage isnt @commentPage
      @goBack()
    paddingTop = 50
    for ci in @commentsItems
      if ci.markData.markid is markid
        ci.J.siblings().removeClass "focus"
        targetTop = ci.dom.offsetTop - paddingTop
        @commentPage.J.animate scrollTop:targetTop,"normal","swing",=>
          ci.J.addClass "focus"          
        return true
  resetStack:->
    @pageStack = []
    last = null
    return this
  goInto:(page,callback)->
    last = @pageStack[@pageStack.length - 1]
    if last then last.leaveToLeft()
    @pageStack.push page
    page.enterFromRight(callback)
    @currentPage = page
    return this
  goBack:(callback)->
    current = @pageStack.pop()
    if not current
      console.error "no page to go back"
      return false
    current.leaveToRight()
    @currentPage = @pageStack[@pageStack.length - 1]
    @currentPage.enterFromLeft(callback)
    return this
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
    contentJ.slideUp "fast"
    hintJ.fadeOut "normal"
  showEditPage:(type,inputData,success,fail)->
    @editPage.init type,inputData
    @UI['edit-accept-btn'].onclick = =>
      content = CKEDITOR.instances.editPageEditor.getData()
      if not content.replace(" ","")
        return alert "content is required!"
      success content if success
      @goBack()
    @UI['edit-cancel-btn'].onclick = =>
      fail() if fail
      @goBack()
    @goInto @editPage
    return @editPage
  showSingleComment:(commentData,commentsItem,markData)->
    @singleCommentPage.init commentData,commentsItem
    @singleCommentPage.UI.header.onclick = (evt)=>
      @app.scrollToRectMark markData
    @goInto @singleCommentPage
  commentsItemActive:(commentsItem)->
    @app.scrollToRectMark commentsItem.markData
    commentsItem.J.addClass("focus").siblings().removeClass("focus")
  addComment:(commentsItem)->
    success = (content)=>
      @app.addCommentToMark content,commentsItem.markData
    @showEditPage "addComment",null,success
        
class CommentsItem extends Suzaku.Widget
  constructor:(rightSection,comments,markData)->
    super window.tpls['comments-item']
    @rightSection = rightSection
    @comments = comments
    @markData = markData
    @markid = markData.markid
    @toggleItems = []
    @unfoldBtn = null
    @folded = true
    @initBtns()
    if @comments.length > 3
      first = @addItem @comments[0]
      @insertUnfoldBtn first
      @addItem @comments[@comments.length - 1]
      @UI['fold'].onclick = (evt)=>
        evt.stopPropagation()
        @fold()
    else
      for c in @comments
        @addItem c
  updateVoteupNum:(commentid,praisenum)->
    @J.find(".id-#{commentid} .vote-up-num").text praisenum
  updateReplyNum:(commentid,replynum)->
    @J.find(".id-#{commentid} .reply-num").text replynum
  initBtns:->
    @dom.onclick = =>
      @rightSection.commentsItemActive this
    @UI['add-comment'].onclick = (evt)=>
      @rightSection.addComment this
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
    item.J.addClass "id-#{data.commentid}"
    item.UI.content.J.html data.content
    item.UI.nickname.J.text data.nickname
    item.UI['reply-num'].J.text data.replynum
    item.UI['vote-up-num'].J.text data.praisenum
    item.dom.onclick = => @rightSection.showSingleComment item.data,this,@markData
    item.appendTo @UI.list
    return item
  insertUnfoldBtn:(target)->
    item = new Suzaku.Widget @UI['unfold-btn-tpl'].J.html()
    item.dom.onclick = => @unfold()
    item.after target
    item.UI['num'].J.text @comments.length - 2
    @unfoldBtn = item
    
