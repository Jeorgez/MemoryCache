
var auth = new authentication();


$(document).ready ( function () {
    auth.init();
    
});

function addEvent (elem, type, eventHandle) {
    if (elem == null || typeof(elem) == 'undefined') return;
    if ( elem.addEventListener ) {
        elem.addEventListener( type, eventHandle, false );
    } else if ( elem.attachEvent ) {
        elem.attachEvent( "on" + type, eventHandle );
    } else {
        elem["on"+type]=eventHandle;
    }
}

// ---------------------------------------------------------------------------------------------------- //
// ------------------------------------------- Popup Window ------------------------------------------- //
// ---------------------------------------------------------------------------------------------------- //

function popup_window (properties) {
    var self    = this;
    var title   = properties.title  ? properties.title  : "";
    var html    = properties.html   ? properties.html   : "&nbsp;";
    var onShow  = properties.onShow ? properties.onShow : function(){};
    var onHide  = properties.onHide ? properties.onHide : function(){};
    var onClose = properties.onClose ? properties.onClose : function(){};
    
    this.htmlElement            = document.createElement("div");
    var windowSubstrate         = document.createElement("div");
    var windowBodyWrapper       = document.createElement("div");
    
    this.htmlElement.className  = "pw_element";
    windowSubstrate.className   = "pw_substrate";
    windowBodyWrapper.className = "pw_body_wrapper";
    
    this.htmlElement.appendChild ( windowSubstrate );
    this.htmlElement.appendChild ( windowBodyWrapper );
    
    var windowTitle             = document.createElement("div");
    var windowTitleText         = document.createElement("div");
    var windowCloseBtn          = document.createElement("div");
    var clearPan                = document.createElement("div");
    var windowBody              = document.createElement("div");
    windowTitle.className       = "pw_title";
    windowTitleText.className   = "pw_title_text";
    windowCloseBtn.className    = "pw_close_btn";
    clearPan.className          = "clear";
    windowBody.className        = "pw_body";
    
    windowTitle.appendChild(windowTitleText);
    windowTitle.appendChild(windowCloseBtn);
    windowTitle.appendChild(clearPan);
    
    windowBodyWrapper.appendChild(windowTitle);
    windowBodyWrapper.appendChild(windowBody);
    
    $(windowSubstrate).css("opacity", "0.7");
    $(windowCloseBtn).click(function () {
        self.close();
    });
    this.title = function (title) {
        return $(windowTitleText).text(title);
    };
    this.html = function (html) {
        return $(windowBody).html(html);
    };
    this.resize = function () {
        var wWidth      = $(window).width() - $(windowBodyWrapper).width();
        var wHeight     = $(window).height() - $(windowBodyWrapper).height();
        var posTop      = (wHeight - (wHeight % 2))/ 2;
        var posLeft     = (wWidth - (wWidth % 2)) / 2;
        $(windowBodyWrapper).css({
            "top"   : posTop + "px",
            "left" : posLeft + "px"
        });
    };
    this.show = function () {
        $(document.body).append( self.htmlElement );
        self.resize();
        onShow();
    };
    this.hide = function () {
        $(self.htmlElement).detach();
        onHide();
    };
    this.close = function () {
        self.hide();
        onClose(); 
    };
    if (title) self.title(title); 
    if (html) self.html(html);
    addEvent(window, "resize", self.resize);
}

// ---------------------------------------------------------------------------------------------------- //
// ------------------------------------------- Error Panel -------------------------------------------- //
// ---------------------------------------------------------------------------------------------------- //

function error_panel () {
    this.html               = document.createElement("div");
    var error_panel         = document.createElement("div");
    error_panel.className   = "error";
    this.html.appendChild(error_panel);
    
    this.message = function (msg) {
        $(error_panel).html(msg);
    };
    
    this.get = function () {
        return this.html;
    };
    
    this.show = function () {
        var width = $(this.html.parentNode).outerWidth();
        $(this.html).css({
            "display"   : "",
            "width"     : width +"px"
        });
    };
    
    this.hide = function () {
        $(this.html).css("display", "none");
    };
    this.hide();
}

// ---------------------------------------------------------------------------------------------------- //
// ------------------------------------------ Authentication ------------------------------------------ //
// ---------------------------------------------------------------------------------------------------- //

function authentication () {
    var self    = this;
    this.host   = "";
    this.port   = "";
    this.init   = function () {
        if (self.host && self.port) {
            self.ajax_check(self.host, self.port, function (response, status) {
                if(status == "success" && typeof response == "object" && response.success){
                    self.window.hide();
                } else {
                    self.window.show();
                }
            });
        } else {
            self.window.show();
        }
    };
    
    this.ajax_check = function (host, port, callback) {
        $.ajax({
            type: "GET",
            url: "http://"+host+":"+port+"/rest/storages",
            cache: false,
        }).always( function (response, status) {
            callback(response, status);
        });
    };
    
    this.check = function () {
        self.ajax_check(self.host, self.port, function (response, status) {
            if (status == "success") {
                if(typeof response == "object") {
                    if(response.success){
                        self.window.hide();
                        return;
                    }
                }
                err.message("Сервер прислал не правильный ответ, проверьте правильность данных");
            } else {
               err.message("Не удалось подключиться к серверу, проверьте правильность данных");
            }
            err.show();
            self.window.resize();
        });
    };
    
    // Error panel
    var err             = new error_panel();
    
    // Host
    var hostDiv         = document.createElement("div");
    hostDiv.className   = "auth_host";
    var hostInput       = document.createElement("input");
    hostInput.type      = "text";
    hostInput.id        = "auth_host";
    hostDiv.innerHTML   = "Хост:&nbsp;";
    hostDiv.appendChild (hostInput);
    $(hostInput).keypress( function (event) {
        if(event.which == 13) { // Enter
            $("#cnnt_btn").click();
        }
    });
    // Port
    var portDiv         = document.createElement("div");
    portDiv.className   = "auth_port";
    var portInput       = document.createElement("input");
    portInput.type      = "text";
    portInput.id        = "auth_port";
    portDiv.innerHTML   = "&nbsp;:&nbsp;";
    portDiv.appendChild (portInput);
    
    $(portInput).keypress( function (event) {
        if(event.which == 13) { // Enter
            $("#cnnt_btn").click();
        }
        var cstr = String.fromCharCode(event.which);
        if((event.which != 8 && isNaN(cstr)) // If char isn't backspace and isn't number 
            || event.which == 32){          // or it's space then prevent event
           event.preventDefault();
        }
    });
    
    // Connect Button
    var connDiv         = document.createElement("div");
    connDiv.className   = "cnnt_btn";
    connDiv.id          = "cnnt_btn";
    connDiv.innerHTML   = "Подключиться";
    $(connDiv).click( function () {
        self.host   = $(hostInput).val();
        self.port   = $(portInput).val();
        self.check();
    });
    
    var clearDiv         = document.createElement("div");
    $(clearDiv).css ("clear", "both");
    // HTML
    var html            = document.createElement("div");
    html.appendChild (err.get());
    html.appendChild (hostDiv);
    html.appendChild (portDiv);
    html.appendChild (connDiv);
    html.appendChild (clearDiv);
    
    this.window = new popup_window ({
        title   :   "Введите данные для подключения",
        html    :   html,
        onClose : function () {
            self.window.show();
        }
    });
    $(hostInput).val("127.0.0.1");
    $(portInput).val("18080");
}











