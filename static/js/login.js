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
        url:'//localhost:8005/login',
        type:'POST',
        data:{
          email:emailInput.val(),
          psw:pswInout.val()
        },
        dataType:'json',
        success:function(data,xhr){
          if(data['flag']==1){
            console.log(2)
            window.location.href='//localhost:8005/home'
          }
          else{
            return loginAlert.fadeIn()
          }
        }
      })
    });
    emailInput.focus(function() {
      return loginAlert.fadeOut();
    });
    return pswInout.focus(function() {
      return loginAlert.fadeOut();
    });
  });

}).call(this);
