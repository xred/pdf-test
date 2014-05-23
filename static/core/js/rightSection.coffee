Utils = Suzaku.Utils
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
      when "addReply" then @UI['add-reply-options'].J.show()
    CKEDITOR.instances.editPageEditor.setData(inputData)
    
class SingleCommentPage extends RightSectionPage
  constructor:(target,@rightSection)->
    target.J.html window.tpls['single-comment-item']
    super target
    @replyItems = []
    @api = @rightSection.app.api
    @UI.back.onclick = (evt)=>
      evt.stopPropagation()
      @rightSection.goBack()
  init:(commentData,commentsItem)->
    @commentData = commentData
    @commentsItem = commentsItem
    @UI.nickname.J.text commentData.nickname
    @UI.date.J.text Utils.parseTime(commentData.datetime*1000,"Y-M-D")
    @UI["vote-up-num"].J.text commentData.praisenum
    @UI['vote-up'].onclick = => @voteUpComment()
    @UI['vote-down'].onclick = => @voteDownComment()
    @UI['reply-btn'].onclick = => @addReply()
    @UI.content.J.html commentData.content
    @UI['go-to-editer'].onclick = =>
      content = @UI['add-reply-content'].value
      @addReply null,content
    @UI['add-reply-confirm'].onclick = =>
      content = @UI['add-reply-content'].value
      if not content or content.replace(" ","").length is 0
        alert "you cannot add a empty reply"
        return false
      @api.addReply @commentData.commentid,content,=>
        @UI['add-reply-content'].value = ""
        window.showMessage "Your reply has been added successfully."
        @initReplys =>
          @commentsItem.updateReplyNum @commentData.commentid,@replyItems.length
    @initReplys()
    return null
  initReplys:(callback)->
    i.remove() for i in @replyItems
    @replyItems = []
    @UI['reply-list'].J.html "<div class='loading-mark'></div>"
    @api.getReplys @commentData.commentid,(res)=>
      @UI['reply-list'].J.html ""
      if not res.success
        window.showMessage res.error_msg,"e"
        return false
      #res.replys = [1..5]
      if not res.replys
        @UI['reply-list'].J.html "<p>No replys. click the reply icon to add one.</p>"
        return false
      @UI['replys-num'].J.html("#{res.replys.length} replys").show()
      tpl = @UI['single-reply-li-tpl'].J.html()
      for r in res.replys
        item = new ReplyItem tpl,r
        item.appendTo @UI['reply-list']
        item.on "replyToThis",(replyItems)=>
          @UI['add-reply-content'].focus()
          @UI['add-reply-content'].J.text "@#{replyItems.data.nickname} "
        @replyItems.push item
      callback() if callback
  voteUpComment:->
    @api.voteupComment @commentData.commentid,(res)=>
      if not res.success
        return console.error res.error_msg
      @commentData.praisenum = res.praisenum
      @UI['vote-up-num'].J.text res.praisenum
      @commentsItem.updateVoteupNum @commentData.commentid,res.praisenum
  voteDownComment:->
    @api.votedownComment @commentData.commentid,(res)=>
      if not res.success
        return console.error res.error_msg
      @commentData.praisenum = res.praisenum
      @UI['vote-up-num'].J.text res.praisenum
      @commentsItem.updateVoteupNum @commentData.commentid,res.praisenum
  addReply:(target,content = null)->
    console.log "add reply"
    @rightSection.showEditPage "addReply",content,(content)=>
      @api.addReply @commentData.commentid,content,=>
        window.showMessage "Your reply has been added successfully."
        @initReplys =>
          @commentsItem.updateReplyNum @commentData.commentid,@replyItems.length
            
class window.RightSection extends Suzaku.Widget
  constructor:(app)->
    super "#right-section"
    @app = app
    @api = app.api
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
    @initResize()
    @initComments()
    @goInto @commentPage
  initResize:->
    @UI.resizer.onmousedown = (evt)=>
      mouseStartPos = x:evt.clientX,y:evt.clientY
      oldRightSectionWidth = @dom.offsetWidth
      window.globalMouseListener.on "mousemove","rightSectionResize",(evt)=>
        x = evt.clientX
        newWidth = oldRightSectionWidth - (x - mouseStartPos.x)
        @J.css "width",newWidth
        $("#viewerContainer").css "margin-right",newWidth
    @UI.resizer.onmouseup = =>
      window.globalMouseListener.off "mousemove","rightSectionResize"
  initComments:->
    i.remove() for i in @commentsItems
    @commentsItems = []
    @app.marks.sort (a,b)->
      return a.pageid - b.pageid or a.marky - b.marky
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
        return window.showMessage "content is required!","error"
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
  addComment:(commentsItem,content)->
    markData = commentsItem.markData
    @showEditPage "addComment",content,(content)=>
      markid = markData.markid
      @api.addCommentToMark content,markid,(res)=>
        window.showMessage "Comment added successfully."
        if not res.success
          window.showMessage res.error_msg,"error"
        @app.initComments =>
          @initComments().resetStack().goInto @commentPage,=>
            @scrollToMarkComments markid
            @app.scrollToRectMark markData
            
class CommentsItem extends Suzaku.Widget
  constructor:(rightSection,comments,markData)->
    super window.tpls['comments-item']
    @rightSection = rightSection
    @app = @rightSection.app
    @api = @rightSection.api
    @id = markData.markid
    @dom.id = "comments-#{@id}"
    @comments = comments
    @markData = markData
    @markid = markData.markid
    @toggleItems = []
    @unfoldBtn = null
    @folded = true
    @liTpl = @UI['single-comment-li-tpl'].J.html();
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
    @UI['add-comment'].onclick = =>
      @UI['add-comment-box'].J.toggleClass "hide"
      if not @UI['add-comment-box'].J.hasClass "hide"
        @UI['add-comment-content'].focus()
    @UI['go-to-editer'].onclick = =>
      content = @UI['add-comment-content'].value
      @rightSection.addComment this,content
    @UI['add-comment-cancel'].onclick = =>
      @UI['add-comment-box'].J.addClass "hide"
    @UI['add-comment-confirm'].onclick = =>
      content = @UI['add-comment-content'].value
      if not content or content.replace(" ","").length is 0
        alert "You cannot add an empty comment!"
        return false
      markid = @markData.markid
      @api.addCommentToMark content,markid,(res)=>
        window.showMessage "Comment added successfully."
        @UI['add-comment-content'].value = ""
        @UI['add-comment-box'].J.addClass "hide"
        if not res.success
          window.showMessage res.error_msg,"error"
        @app.initComments =>
          @rightSection.initComments()
          @rightSection.scrollToMarkComments markid
          @app.scrollToRectMark @markData
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
    item = new CommentsItemCommentLi @liTpl,data,this,@api
    item.on "showSingleComment",=>
      @rightSection.showSingleComment data,this,@markData
    item.appendTo @UI.list
    return item
  insertUnfoldBtn:(target)->
    item = new Suzaku.Widget @UI['unfold-btn-tpl'].J.html()
    item.dom.onclick = => @unfold()
    item.after target
    item.UI['num'].J.text @comments.length - 2
    @unfoldBtn = item

class CommentsItemCommentLi extends Suzaku.Widget
  constructor:(tpl,data,@commentsItem,@api)->
    super tpl
    @data = data
    @J.addClass "id-#{data.commentid}"
    @UI.content.J.html data.content
    @textContent = @UI.content.textContent
    @UI.content.J.text @textContent
    @UI.nickname.J.text data.nickname
    @UI.date.J.text Utils.parseTime data.datetime*1000,"Y-M-D"
    @UI['reply-num'].J.text data.replynum
    @UI['vote-up-num'].J.text data.praisenum
    @UI['vote-up'].onclick = => @voteUpComment()
    @UI['vote-down'].onclick = => @voteDownComment()
    @UI['fold-btn'].onclick = (evt)=>
      evt.stopPropagation()
      @toggleUp()
    @UI['reply-btn'].onclick = (evt)=>
      evt.stopPropagation()
      @emit "showSingleComment"
    @dom.onclick = => @toggleDown()
  toggleDown:->
    @J.removeClass "folded"
    @UI.content.J.addClass "real-content-section"
    @UI.content.J.html @data.content
  toggleUp:->
    @J.addClass "folded"
    @UI.content.J.removeClass "real-content-section"
    @UI.content.J.text @textContent
  voteUpComment:->
    return false if @J.hasClass "folded"
    @api.voteupComment @data.commentid,(res)=>
      if not res.success
        return console.error res.error_msg
      @data.praisenum = res.praisenum
      @UI['vote-up-num'].J.text res.praisenum
      @commentsItem.updateVoteupNum @data.commentid,res.praisenum
  voteDownComment:->
    return false if @J.hasClass "folded"
    @api.votedownComment @data.commentid,(res)=>
      if not res.success
        return console.error res.error_msg
      @data.praisenum = res.praisenum
      @UI['vote-up-num'].J.text res.praisenum
      @commentsItem.updateVoteupNum @data.commentid,res.praisenum
    
class ReplyItem extends Suzaku.Widget
  constructor:(tpl,data)->
    super tpl
    @data = data
    @UI['reply-nickname'].J.text data.nickname
    @UI['reply-date'].J.text Utils.parseTime(data.datetime*1000,"Y-M-D")
    @UI['reply-content'].J.html data.content
    @UI['reply-vote-up-num'].J.text data.praisenum
    @UI['reply-reply-btn'].onclick = =>
      @replyToThisReply()
  replyToThisReply:->
    console.log "reply to",this
    @emit "replyToThis",this
