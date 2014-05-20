(function() {
  jQuery(document).ready(function() {
    console.log(1)
    var emailInput, isCorrect, loginAlert, loginBtn, pswInout;
    isCorrect = false;
    loginAlert = jQuery("#alert-login");
    loginBtn = jQuery("#btn-login");
    emailInput = jQuery("#inputEmail");
    pswInout = jQuery("#inputPassword");
    loginBtn.click(function() {
      // console.log(1)
      // return loginAlert.fadeIn();
      req = jQuery.ajax({
        url:'/login',
        type:'POST',
        data:{
          email:emailInput.val(),
          psw:pswInout.val()
        },
        dataType:'json',
        success:function(data,xhr){
          if(data['flag']==1){
            console.log(2)
            window.location = '/home'
          }
          else{
            return loginAlert.fadeIn()
          }
        }
      })
    });
    $("input").keydown(function(e){
      var curKey = e.which;
      if(curKey==13){
        $(loginBtn).click();
        return false
      }
    });
    // $("input#inputEmail").keydown(function(e){
    //   var curKey = e.which;
    //   if(curKey==13){
    //     $(loginBtn).click();
    //     return false
    //   }
    // });
    // $("input#inputPassword").keydown(function(e){
    //   var curKey = e.which;
    //   if(curKey==13){
    //     $(loginBtn).click();
    //     return false
    //   }
    // });
    emailInput.focus(function() {
      return loginAlert.fadeOut();
    });
    return pswInout.focus(function() {
      return loginAlert.fadeOut();
    });
  });

}).call(this);
