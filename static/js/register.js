(function() {
  jQuery(document).ready(function() {
    var addRegisterDis, checkEmail, checkPsw, checkPswEmpty, emailAlert, emailInput, isCorrect, pswAlert, pswInput1, pswInput2, registerBtn, removeRegisterDis, validateEmail;
    isCorrect = false;
    emailInput = jQuery("#inputEmail");
    emailAlert = jQuery("#alert-email");
    emailInput.blur(function() {
      if (!checkEmail()) {
        emailAlert.fadeIn();
        return addRegisterDis();
      } else if (checkPsw() && !checkPswEmpty()) {
        return removeRegisterDis();
      }
    });
    emailInput.focus(function() {
      return emailAlert.fadeOut();
    });
    registerBtn = jQuery("#btn-register");
    pswInput1 = jQuery("#inputPassword1");
    pswInput2 = jQuery("#inputPassword2");
    pswAlert = jQuery("#alert-psw");
    nicknameInput = jQuery("#inputNickname");
    registerBtn.click(function(){
    // console.log(1)
    req = jQuery.ajax({
      url:'/register',
      type:'POST',
      data:{
        email:emailInput.val(),
        psw:pswInput1.val(),
        nickname:nicknameInput.val()
      },
      dataType:'json',
      success:function(data,xhr){
        if(data['flag']==1){
          // console.log(1)
          window.location = '/login';
        }
        else{
          // console.log(2)
          addRegisterDis();
          alert('the email or nickname has been used')
        }
      }
    });

  })
    $("input").keydown(function(e){
      var curKey = e.which;
      if(curKey==13){
        $(registerBtn).click();
        return false
      }
    });

    pswInput2.blur(function() {
      if (!checkPsw()) {
        pswAlert.fadeIn();
        return addRegisterDis();
      } else if (checkEmail() && !checkPswEmpty()) {
        return removeRegisterDis();
      }
    });
    pswInput2.focus(function() {
      return pswAlert.fadeOut();
    });
    nicknameInput.blur(function(){
      return removeRegisterDis();
    });
    checkEmail = function() {
      var emailStr;
      emailStr = emailInput.val();
      return validateEmail(emailStr);
      /*
      signalIndex = emailStr.indexOf "@"
      if (signalIndex is -1) or (signalIndex is emailStr.length-1)
          return no
      else if emailStr.length == 0
          return no 
      else
          return yes
      */

    };
    checkPsw = function() {
      if (!(pswInput2.val() === pswInput1.val())) {
        return false;
      } else {
        console.log(pswInput1.val());
        return true;
      }
    };
    checkPswEmpty = function() {
      if (pswInput1.val().length === 0 && pswInput2.val().length === 0) {
        return true;
      } else {
        return false;
      }
    };
    removeRegisterDis = function() {
      // console.log("dsdas");
      return registerBtn.removeAttr("disabled");
    };
    addRegisterDis = function() {
      return registerBtn.attr("disabled", "disabled");
    };
    return validateEmail = function(email) {
      var re;
      re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
      return re.test(email);
    };
  });


}).call(this);
