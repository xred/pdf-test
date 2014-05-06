// Generated by CoffeeScript 1.6.3
(function() {
  var App, GlobalMouseListener, Page, RectMark, pdfUrl,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    _this = this;

  console.log("run");

  pdfUrl = null;

  GlobalMouseListener = (function(_super) {
    __extends(GlobalMouseListener, _super);

    function GlobalMouseListener() {
      GlobalMouseListener.__super__.constructor.apply(this, arguments);
      this.unbindEvents();
    }

    GlobalMouseListener.prototype.bindEvents = function() {
      var _this = this;
      document.body.onmousemove = function(evt) {
        return _this.emit("mousemove", evt);
      };
      document.body.onmouseup = function(evt) {
        return _this.emit("mouseup", evt);
      };
      return document.body.onmousedown = function(evt) {
        return _this.emit("mousedown", evt);
      };
    };

    GlobalMouseListener.prototype.unbindEvents = function() {
      document.body.onmousemove = null;
      document.body.onmouseup = null;
      return document.body.onmousedown = null;
    };

    GlobalMouseListener.prototype.on = function() {
      if (!document.body.onmousemove) {
        this.bindEvents();
      }
      return GlobalMouseListener.__super__.on.apply(this, arguments);
    };

    GlobalMouseListener.prototype.off = function() {
      GlobalMouseListener.__super__.off.apply(this, arguments);
      if (Object.keys(this._events).length === 0) {
        return this.unbindEvents();
      }
    };

    return GlobalMouseListener;

  })(Suzaku.EventEmitter);

  App = (function(_super) {
    var newCommentLock;

    __extends(App, _super);

    newCommentLock = false;

    function App() {
      var am, tm,
        _this = this;
      App.__super__.constructor.apply(this, arguments);
      am = new Suzaku.ApiManager;
      am.setPath("");
      tm = new Suzaku.TemplateManager;
      tm.setPath("/core/templates/");
      tm.use("comments-item", "rect-mark", "single-comment-item");
      tm.start(function(tpls) {
        window.tpls = tpls;
        return _this.start();
      });
    }

    App.prototype.start = function() {
      var p, pages, _i, _len, _ref,
        _this = this;
      this.pages = [];
      _ref = pages = $(".page");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        p = _ref[_i];
        this.pages.push(new Page(this, p));
      }
      this.rightSection = new RightSection(this);
      return $("#newComment").on("click", function() {
        if (newCommentLock) {
          return false;
        }
        $("#newComment").addClass("toggled");
        return _this.newComment();
      });
    };

    App.prototype.newComment = function() {
      newCommentLock = true;
      this.emit("newComment");
      return this.rightSection.showNewCommentHint();
    };

    App.prototype.newCommentConfirm = function(page) {
      var fail, success,
        _this = this;
      this.emit("newComment:confirm");
      page.newCommentConfirm();
      success = function(content) {
        console.log(content);
        if (content.replace(" ", "").length === "0") {
          alert("Error: Content is Empty");
        }
        return _this.newCommentSuccessed(page, content);
      };
      fail = function() {
        return _this.newCommentCanceled(page);
      };
      this.rightSection.hideNewCommentHint();
      return this.rightSection.showEditPage("newComment", null, success, fail);
    };

    App.prototype.newCommentSuccessed = function(page, content) {
      newCommentLock = false;
      page.newCommentCompleted();
      $("#newComment").removeClass("toggled");
      console.log("new comment page:", targetPage, "content:", content);
      return targetPage.initUserMarks();
    };

    App.prototype.newCommentCanceled = function(page) {
      var p, _i, _len, _ref;
      newCommentLock = false;
      if (page) {
        page.newCommentCompleted();
      } else {
        _ref = this.pages;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          p = _ref[_i];
          p.newCommentCompleted();
        }
      }
      return $("#newComment").removeClass("toggled");
    };

    App.prototype.initUserMarks = function() {
      var page, _i, _len, _ref, _results;
      _ref = this.pages;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        page = _ref[_i];
        _results.push(page.initUserMarks);
      }
      return _results;
    };

    return App;

  })(Suzaku.EventEmitter);

  RectMark = (function(_super) {
    __extends(RectMark, _super);

    function RectMark(type) {
      if (type == null) {
        type = "normal";
      }
      RectMark.__super__.constructor.call(this, window.tpls['rect-mark']);
      if (type === "temp") {
        this.tempType();
      }
    }

    RectMark.prototype.tempType = function() {
      var _this = this;
      this.J.addClass("temp");
      this.dom.onmousedown = function(evt) {
        return _this.emit("drag", evt.clientX, evt.clientY);
      };
      return this.UI['resizer'].onmousedown = function(evt) {
        evt.stopPropagation();
        evt.preventDefault();
        return _this.emit("resize", evt.clientX, evt.clientY);
      };
    };

    RectMark.prototype.getInfo = function() {
      var obj;
      obj = {
        left: this.dom.offsetLeft,
        top: this.dom.offsetTop,
        width: this.dom.offsetWidth,
        height: this.dom.offsetHeight
      };
      return obj;
    };

    return RectMark;

  })(Suzaku.Widget);

  Page = (function(_super) {
    __extends(Page, _super);

    function Page(app, pageContainerDom) {
      var id,
        _this = this;
      Page.__super__.constructor.call(this, pageContainerDom);
      id = this.dom.id.replace("pageContainer", "");
      this.markingWrapper = new Suzaku.Widget("<div class='marking-wrapper'></div>");
      this.markingWrapper.appendTo(this.dom);
      this.textLayerJ = this.J.find('.textLayer');
      this.marks = [];
      this.app = app;
      app.on("newComment", function() {
        return _this.newCommentActive();
      });
      app.on("newComment:confirm", function() {
        return _this.clearListeners();
      });
      app.on("newComment:active", function(page) {
        if (page !== _this) {
          return _this.clearListeners();
        }
      });
    }

    Page.prototype.clearListeners = function() {
      this.dom.onmouseup = null;
      this.dom.onmousedown = null;
      return this.dom.onmousemove = null;
    };

    Page.prototype.newCommentActive = function() {
      var _this = this;
      this.dom.onmousedown = function(evt) {
        var r, x, y;
        if (_this.tempRectMark) {
          return false;
        }
        _this.app.emit("newComment:active", _this);
        evt.preventDefault();
        _this.textLayerJ = _this.J.find('.textLayer');
        r = _this.textLayerJ[0].getBoundingClientRect();
        x = evt.clientX - r.left;
        y = evt.clientY - r.top;
        _this.mouseStartPos = {
          x: x,
          y: y
        };
        _this.tempRectMark = new RectMark("temp");
        _this.tempRectMark.J.css({
          left: x,
          top: y
        });
        return _this.tempRectMark.appendTo(_this.markingWrapper);
      };
      this.dom.onmouseup = function(evt) {
        if (!_this.mouseStartPos) {
          return false;
        }
        _this.mouseStartPos = null;
        _this.clearListeners();
        return _this.app.newCommentConfirm(_this);
      };
      return this.dom.onmousemove = function(evt) {
        var height, left, r, sp, top, width, x, y;
        if (!_this.mouseStartPos) {
          return false;
        }
        r = _this.textLayerJ[0].getBoundingClientRect();
        x = evt.clientX - r.left;
        y = evt.clientY - r.top;
        sp = _this.mouseStartPos;
        if (y < sp.y) {
          top = y;
        } else {
          top = sp.y;
        }
        if (x < sp.x) {
          left = x;
        } else {
          left = sp.x;
        }
        width = Math.abs(x - sp.x);
        height = Math.abs(y - sp.y);
        return _this.tempRectMark.J.css({
          left: left,
          top: top,
          width: width,
          height: height
        });
      };
    };

    Page.prototype.newCommentConfirm = function() {
      var action, defaultInfo,
        _this = this;
      action = "none";
      defaultInfo = this.tempRectMark.getInfo();
      this.tempRectMark.on("drag", function(x, y) {
        _this.mouseStartPos = {
          x: x,
          y: y
        };
        return action = "drag";
      });
      this.tempRectMark.on("resize", function(x, y) {
        _this.mouseStartPos = {
          x: x,
          y: y
        };
        return action = "resize";
      });
      window.globalMouseListener.on("mouseup", "newCommentConfirm", function(evt) {
        if (!_this.mouseStartPos) {
          return false;
        }
        action = "none";
        _this.mouseStartPos = null;
        return defaultInfo = _this.tempRectMark.getInfo();
      });
      return window.globalMouseListener.on("mousemove", "newCommentConfirm", function(evt) {
        var dx, dy, height, width;
        if (!_this.mouseStartPos) {
          return false;
        }
        dx = evt.clientX - _this.mouseStartPos.x;
        dy = evt.clientY - _this.mouseStartPos.y;
        switch (action) {
          case "drag":
            return _this.tempRectMark.J.css({
              left: defaultInfo.left + dx,
              top: defaultInfo.top + dy
            });
          case "resize":
            width = defaultInfo.width + dx;
            height = defaultInfo.height + dy;
            if (width < 5) {
              width = 5;
            }
            if (height < 5) {
              height = 5;
            }
            return _this.tempRectMark.J.css({
              width: width,
              height: height
            });
          default:
            return console.log("error status", action);
        }
      });
    };

    Page.prototype.newCommentCompleted = function() {
      if (!this.tempRectMark) {
        return false;
      }
      window.globalMouseListener.off("mouseup", "newCommentConfirm");
      window.globalMouseListener.off("mousemove", "newCommentConfirm");
      this.tempRectMark.remove();
      return this.tempRectMark = null;
    };

    Page.prototype.initUserMarks = function(marks) {
      "show user marks";
      return true;
    };

    return Page;

  })(Suzaku.Widget);

  RunPDFViewer(pdfUrl, function() {
    var ckConfig;
    window.globalMouseListener = new GlobalMouseListener();
    new App();
    ckConfig = {
      height: 400
    };
    return CKEDITOR.replace("editPageEditor", ckConfig);
  });

}).call(this);
