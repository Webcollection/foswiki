/***********************************
QuickMenu Class v1.1
(c) 2006 Vernon Lyon  (original code can be found with the QuickMenuSkin)
v2 2008 David Patterson - changes in original code to support the NuSkin:
- multiple menubars possible on the page
- each menubar is a pre-created html table with links pre-assigend - still visible and useable even when js is disabled
- only ShowOnHover because menu headers are usually links as well
- sub-menu headers can also be links
- a page/web/user can add its own entries to a menu header
Note that the NuSkin assumes the availability of the jQuery 1.2.6 (and above) core code.
***********************************/

var QuickMenu = {
  Set : {
    HideTimeout : 500
  },
  User : {
  },
  Timer : null,
  ShownMenu : null,
  classname : null,
  Menu : function (menubutton,tableid) {
	var table = document.getElementById(tableid);
	if (!table) return;
	this.Button = document.getElementById(menubutton);
	if (this.Button == null) return;
	this.Button.defaultClass = classname = table.className;
	this.Button.className = classname + "-button";
	var menubar = menubutton;
    this.MenuBar = this.Button.MenuBar = menubar;
//    if (menubar.ShowOnHover == null) menubar.ShowOnHover = QuickMenu.Set.ShowOnHover;

    this.Button.onmouseover = function () {
      if (this.MenuList) {
		if (this.MenuList.Shown) {
			clearTimeout(QuickMenu.Timer);
			QuickMenu.Timer = null;
			return;
		} else {
			clearTimeout(QuickMenu.Timer);
			QuickMenu.HideAll();
			this.className = this.defaultClass + "-button-click";
			if (this.Dot) {
				pos = findAbsPos(this);
				this.Dot.style.top = pos.y + this.offsetHeight - 1 + "px";
				this.Dot.style.left = pos.x + "px";
				this.Dot.style.visibility = "visible";
			}
			this.MenuList.Show();
		}
      } else {
        if (QuickMenu.ShownMenu) {
          clearTimeout(QuickMenu.Timer);
          QuickMenu.HideAll();
        }
        this.className = this.defaultClass + "-button-over";
      }
    }

    this.Button.onmouseout = function () {
      if (this.className == (this.defaultClass + "-button-over")) this.className = this.defaultClass + "-button";
      if (this.MenuList && this.MenuList.Shown && !QuickMenu.Timer)
        QuickMenu.Timer = setTimeout("QuickMenu.HideAll()", QuickMenu.Set.HideTimeout);
    }

 /*   this.Button.onclick = function () {
      if (this.Link) {
        window.location = this.Link;
      } else if (this.Action) {
        eval (this.Action);
      } else if (this.MenuList.Shown && !this.MenuBar.ShowOnHover) {
        this.MenuList.Hide();
        if (this.Dot) this.Dot.style.visibility = "hidden";
        this.className = classname + "-button-over";
      } else {
        QuickMenu.HideAll();
        this.className = classname + "-button-click";
        if (this.Dot) {
          pos = findAbsPos(this);
          this.Dot.style.top = pos.y + this.offsetHeight - 1 + "px";
          this.Dot.style.left = pos.x + "px"
          this.Dot.style.visibility = "visible";
        }
        this.MenuList.Show();
      }
    }
*/

  },
  MenuList : function (parent, menubar) {
    this.Parent = parent;
    this.MenuBar = menubar;
    this.Items = [];
    if (QuickMenu.User.Ie) {
      this.Iframe = document.createElement("IFRAME");
      this.Iframe.frameBorder = 0;
      this.Iframe.scrolling = "no";
      this.Iframe.marginWidth = 0;
      this.Iframe.style.position = "absolute";
      this.Iframe.style.display = "none";
      document.body.appendChild(this.Iframe);
    }
    this.Outer = document.createElement("DIV");
    this.Outer.className = classname + "-menu";
    this.Outer.style.left = this.Outer.style.top = 0;
    this.Shadow = document.createElement("DIV");
    this.Shadow.className = classname + "-menu-shadow";
    if (QuickMenu.User.Ie) {
      this.Shadow.style.filter = 'progid:DXImageTransform.Microsoft.Blur(pixelradius=2,makeshadow="true",ShadowOpacity=.4)';
    }
    this.Inner = document.createElement("DIV");
    this.Inner.className = classname + "-menulist";
    this.Outer.style.left = this.Outer.style.top = "0px";

    this.Outer.appendChild(this.Shadow);
    this.Outer.appendChild(this.Inner);
    document.body.appendChild(this.Outer);
  },
  MenuItem : function (parent, text, action, icon, tip) {
    this.Parent = parent;
    this.Row = document.createElement("A");
    this.Row.ParentMenu = parent;

    if (text) {
      if (action) {
        if (action.substring(0,1) == ":") {
          this.Row.MenuList = new QuickMenu.MenuList(this, parent.MenuBar);
          this.Row.style.cursor = "default";
          if (action.substring(1)) {
	        if (action.substring(1,2) == ":") {
		        this.Row.href = action.substring(2);
		        this.Row.style.cursor = "pointer";
	        }
      		else {
            	if (!parent.Parent.Button) parent[action.substring(1)] = this.Row.MenuList;
            	else parent.Parent[action.substring(1)] = this.Row.MenuList;
          	}
      	  }
        } else if (action.substring(0,3) == "js:") {
          this.Row.Action = action.substring(3);
          this.Row.style.cursor = "pointer";
        } else {
          this.Row.href = action;
        }

        this.Row.onclick = function () {
          if (!this.MenuList) QuickMenu.HideAll();
        }
      } else {
        this.Row.className = "disabled";
        this.Row.style.cursor = "default";
      }
      this.Text = document.createElement("DIV");
      this.Text.className = this.Row.MenuList ? classname + "-menuitem-arrow" : classname + "-menuitem";
      this.Text.appendChild(document.createTextNode(text));
      if (icon) {
        this.Icon = document.createElement("IMG");
        this.Icon.src = icon;
        this.Row.appendChild(this.Icon);
      }
      if (tip) this.Row.title = tip;
      this.Row.appendChild(this.Text);
    } else {
      this.Row.className = "separator";
      this.Row.appendChild(document.createElement("DIV"));
    }

    this.Row.onmouseover = function () {
      clearTimeout(QuickMenu.Timer);
      QuickMenu.Timer = null;
      if (!text || !action || this.className == "over")
        return;
      while (QuickMenu.ShownMenu != this.ParentMenu) QuickMenu.ShownMenu.Hide();
      this.className = "over";
      if (this.MenuList) this.MenuList.Show();
    }
    this.Row.onmouseout = function () {
      if (!this.MenuList && this.className == "over") {
        this.className = "";
      }
      if (!QuickMenu.Timer && QuickMenu.ShownMenu)
        QuickMenu.Timer = setTimeout("QuickMenu.HideAll()", QuickMenu.Set.HideTimeout);
    }
    parent.Inner.appendChild(this.Row);
  },
  HideAll : function () {
    QuickMenu.Timer = "HideAll"; // Ensure that no timer gets set while hiding
    var menu;
    while (menu = QuickMenu.ShownMenu) {
      menu.Hide();
      if (menu.Parent.Button) {
        if (menu.Parent.Button.Dot) menu.Parent.Button.Dot.style.visibility = "hidden";
        menu.Parent.Button.className = menu.Parent.Button.defaultClass + "-button";
      }
    }
    QuickMenu.Timer = null;
  }
}

function findAbsPos(obj) {
  var x, y;
  x = obj.offsetLeft;
  y = obj.offsetTop;
  if (obj.offsetParent) {
    pos = findAbsPos(obj.offsetParent);
    x += pos.x;
    y += pos.y;
  }
  return { x : x, y : y };
}

QuickMenu.Menu.prototype.Add = function (text, action, icon, tip) {
  if (this.Button) {
	if (!this.Button.MenuList) {
		this.Button.MenuList = new QuickMenu.MenuList(this, this.MenuBar);
		this.Items = this.Button.MenuList.Items;
		var buttonid = this.Button.id
		if (/MSIE ((5\.5)|6)/.test(navigator.userAgent) && navigator.platform == "Win32") {
			jQuery(function($){$("a#"+buttonid).wrapInner("<div class='arrow-down-ie6'></div>");});
		} else {
			jQuery(function($){$("a#"+buttonid).wrapInner("<div class='arrow-down'></div>");});
		}
		if (QuickMenu.User.Ie) {
			this.Button.Dot = document.createElement("SPAN");
			this.Button.Dot.appendChild(document.createTextNode(" "));
			this.Button.Dot.style.left = "0px";
			this.Button.Dot.style.backgroundColor = "#315ea3";
			this.Button.Dot.style.visibility = "hidden";
			this.Button.Dot.style.position = "absolute";
			this.Button.Dot.style.width = "1px";
			this.Button.Dot.style.height = "1px";
			this.Button.Dot.style.fontSize = "0px";
			this.Button.Dot.style.zIndex = 3;
			pos = findAbsPos(this.Button);
			this.Button.Dot.style.top = pos.y + this.Button.offsetHeight - 1 + "px";
			this.Button.Dot.style.left = pos.x + "px";
			document.body.appendChild(this.Button.Dot);
		}
	}
	return this.Button.MenuList.Add(text, action, icon, tip);
  }
  else return;
};

QuickMenu.MenuList.prototype.Add = function (text, action, icon, tip) {
  var i = this.Items.length;
  this.Items[i] = new QuickMenu.MenuItem(this, text, action, icon, tip);
  return this.Items[i].Row.MenuList || this.Items[i];
};

QuickMenu.MenuList.prototype.Hide = function () {
  this.Shadow.style.visibility = "hidden";
  this.Outer.style.visibility = "hidden";
  if (this.Iframe) this.Iframe.style.display = "none";
  this.Shown = false;
  if (this.Parent.Button) {
    QuickMenu.ShownMenu = null;
  } else {
    this.Parent.Row.className = "";
    QuickMenu.ShownMenu = this.Parent.Parent;
  }
};

QuickMenu.MenuList.prototype.Place = function () {
  var h, w;
  if (document.documentElement && document.documentElement.clientWidth) {
    h = document.documentElement.clientHeight;
    w = document.documentElement.clientWidth;
  } else if (document.body && document.body.offsetWidth) {
    h = document.body.offsetHeight;
    w = document.body.offsetWidth;
  } else {
    h = innerHeight;
    w = innerWidth;
  }
  if (this.Parent.Button) {
    pos = findAbsPos(this.Parent.Button);
    max = w - this.Outer.offsetWidth - (QuickMenu.User.Ie ? 5 : 3);
    if (max < 0) max = 0;
    this.Outer.style.left = (pos.x > max) ?  max + "px" : pos.x + "px";
    this.Outer.style.top = pos.y + this.Parent.Button.offsetHeight - 1 + "px";
  } else {
    // Find left, right & top
    var l, r, t;
    pos = findAbsPos(this.Parent.Row);
    if (QuickMenu.User.Ie) {
      l = pos.x + 1;
      r = pos.x + this.Parent.Row.offsetWidth - 1;
      t = pos.y;
    } else if (QuickMenu.User.Safari) {
      l = pos.x + 1;
      r = pos.x + this.Parent.Row.offsetWidth - 1;
      t = pos.y - 1;
    } else {
      l = pos.x + 2;
      r = pos.x + this.Parent.Row.offsetWidth;
      t = pos.y;
    }
    var left = (r + this.Outer.offsetWidth + (QuickMenu.User.Ie ? 5 : 3) > w) ? l - this.Outer.offsetWidth : r;
	this.Outer.style.left = ((left <= 0) ? 2 : left) + "px";
    this.Outer.style.top = t - (QuickMenu.User.Ie ? 1 : 0) + "px";
  }
};

QuickMenu.MenuList.prototype.Show = function () {
  QuickMenu.ShownMenu = this;
  this.Place();
  if (this.Iframe) {
    this.Iframe.style.left = this.Outer.style.left;
    this.Iframe.style.top = this.Outer.style.top;
    this.Iframe.style.width = 3 + this.Outer.offsetWidth + "px";
    this.Iframe.style.height = 3 + this.Outer.offsetHeight + "px";
    this.Iframe.style.display = "";
  }
  this.Outer.style.visibility = "visible";
  this.Shadow.style.width = this.Outer.offsetWidth + "px";
  this.Shadow.style.height = this.Outer.offsetHeight + "px";
  this.Shadow.style.visibility = "visible";
  this.Shown = true;
};

QuickMenu.User.v = navigator.userAgent.toLowerCase();
QuickMenu.User.Dom = document.getElementById ? 1 : 0;
QuickMenu.User.Ie = (QuickMenu.User.v.match("msie (5\.5|6|7)") && QuickMenu.User.Dom) ? 1 : 0;
QuickMenu.User.Ie.Bad = (QuickMenu.User.v.match("msie (5\.5|6)") && QuickMenu.User.Dom) ? 1 : 0;
QuickMenu.User.cssCompat = (QuickMenu.User.Ie && document.compatMode == "CSS1Compat") ? 1 : 0;
QuickMenu.User.Gecko = (QuickMenu.User.v.indexOf("gecko") > -1 && QuickMenu.User.Dom) ? 1 : 0;
QuickMenu.User.Safari = (QuickMenu.User.v.indexOf("safari") > -1 && QuickMenu.User.Dom) ? 1 : 0;
QuickMenu.User.Moz = (QuickMenu.User.Gecko && parseInt(navigator.productSub) > 20020512) ? 1 : 0;
QuickMenu.User.Dhtml = (QuickMenu.User.Ie || QuickMenu.User.Moz) ? 1 : 0;
