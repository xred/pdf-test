(function(){
    jQuery(document).ready(function(){
            $("a.moreComments").click(function(event){
                event.preventDefault();
                node = event.target;
                tpl = $(node).prev("ul.comment-list").children(":first");
                // console.log(tpl)
                markid = $(node).parents('div.panel').filter('.panel-default').filter('.one-paper-position-panel').find("div.panel-heading").find('a')[0].innerHTML;
                paperid = $(node).parents("div.panel-body").filter(".paper-panel-body").prev().find("a")[0].innerHTML
                myOrOther = $(node).parent().find("span.panel-comment-title")[0].innerHTML
                req = jQuery.ajax({
                    url:'/home',
                    type:'POST',
                    data:{
                        markid:markid,
                        paperid:paperid,
                        myOrOther:myOrOther
                    },
                    dataType:'json',
                    beforeSend:function(xhr){
                        $(node).html('Loading......');
                        $(node).removeAttr('href');
                    },
                    error:function(data,xhr){
                        console.log(1)
                    },
                    success:function(data,xhr){
                        for (comments in data['comment']){
                            newCommentJ = tpl.clone();
                            // console.log(data['comment'][comments])
                            newCommentJ.find("a.comment-name").html(data['comment'][comments]['comment_name']);
                            // console.log(data['comment'][comments]['comment_name']);
                            newCommentJ.find("a.comment-name").next("span").html('commented '+data['comment'][comments]['comment_date']);
                            newCommentJ.find("div.panel-body>a").html(data['comment'][comments]['content']);
                            newCommentJ.appendTo($(node).prev("ul.comment-list"));
                        }
                        node.remove()
                    }
                })
            })
    })
})()