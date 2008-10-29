var TWikiTiny={twikiVars:null,request:null,metaTags:null,tml2html:new Array(),html2tml:new Array(),getTWikiVar:function(name){if(TWikiTiny.twikiVars==null){var sets=tinyMCE.getParam("twiki_vars","");TWikiTiny.twikiVars=eval(sets);}
return TWikiTiny.twikiVars[name];},expandVariables:function(url){for(var i in TWikiTiny.twikiVars){url=url.replace('%'+i+'%',TWikiTiny.twikiVars[i],'g');}
return url;},enableSave:function(enabled){var status=enabled?null:"disabled";var elm=document.getElementById("save");if(elm){elm.disabled=status;}
elm=document.getElementById("preview");if(elm){elm.style.display='none';elm.disabled=status;}},transform:function(editor,handler,text,onReadyToSend,onReply,onFail){var url=TWikiTiny.getTWikiVar("SCRIPTURL");var suffix=TWikiTiny.getTWikiVar("SCRIPTSUFFIX");if(suffix==null)suffix='';url+="/rest"+suffix+"/WysiwygPlugin/"+handler;var path=TWikiTiny.getTWikiVar("WEB")+'.'
+TWikiTiny.getTWikiVar("TOPIC");TWikiTiny.request=new Object();if(tinyMCE.isIE){TWikiTiny.request.req=new ActiveXObject("Microsoft.XMLHTTP");}else{TWikiTiny.request.req=new XMLHttpRequest();}
TWikiTiny.request.editor=editor;TWikiTiny.request.req.open("POST",url,true);TWikiTiny.request.req.setRequestHeader("Content-type","application/x-www-form-urlencoded");var params="nocache="+encodeURIComponent((new Date()).getTime())
+"&topic="+encodeURIComponent(path)
+"&text="+encodeURIComponent(text);TWikiTiny.request.req.setRequestHeader("Content-length",params.length);TWikiTiny.request.req.setRequestHeader("Connection","close");TWikiTiny.request.req.onreadystatechange=function(){if(TWikiTiny.request.req.readyState==4){if(TWikiTiny.request.req.status==200){onReply();}else{onFail();}}};onReadyToSend();TWikiTiny.request.req.send(params);},initialisedFromServer:false,setUpContent:function(editor_id,body,doc){if(TWikiTiny.initialisedFromServer)return;var editor=tinyMCE.getInstanceById(editor_id);TWikiTiny.switchToWYSIWYG(editor);TWikiTiny.initialisedFromServer=true;},switchToRaw:function(inst){inst.triggerSave(false,true);var text=inst.oldTargetElement.value;for(var i=0;i<TWikiTiny.html2tml.length;i++){var cb=TWikiTiny.html2tml[i];text=cb.apply(inst,[inst,text]);}
TWikiTiny.transform(inst,"html2tml",text,function(){TWikiTiny.enableSave(false);var te=TWikiTiny.request.editor.oldTargetElement;te.value="Please wait... retrieving page from server";},function(){var te=TWikiTiny.request.editor.oldTargetElement;var text=TWikiTiny.request.req.responseText;te.value=text;TWikiTiny.enableSave(true);},function(){var te=TWikiTiny.request.editor.oldTargetElement;te.value="There was a problem retrieving the page: "
+TWikiTiny.request.req.statusText;});var eid=inst.editorId;var id=eid+"_2WYSIWYG";var el=document.getElementById(id);if(el){el.style.display="block";}else{el=document.createElement('INPUT');el.id=id;el.type="button";el.value="WYSIWYG";el.className="twikiButton";el.onclick=function(){tinyMCE.execCommand("mceToggleEditor",null,inst.editorId);return false;}
var pel=inst.oldTargetElement.parentNode;pel.insertBefore(el,inst.oldTargetElement);}
inst.oldTargetElement.onchange=function(){var inst=tinyMCE.getInstanceById(eid);inst.isNotDirty=false;return true;}},switchToWYSIWYG:function(editor){editor.oldTargetElement.onchange=null;TWikiTiny.transform(editor,"tml2html",editor.oldTargetElement.value,function(){TWikiTiny.enableSave(false);var editor=TWikiTiny.request.editor;tinyMCE.setInnerHTML(TWikiTiny.request.editor.getBody(),"<span class='twikiAlert'>Please wait... retrieving page from server.</span>");},function(){var text=TWikiTiny.request.req.responseText;for(var i=0;i<TWikiTiny.tml2html.length;i++){var cb=TWikiTiny.tml2html[i];text=cb.apply(editor,[editor,text]);}
tinyMCE.setInnerHTML(TWikiTiny.request.editor.getBody(),text);TWikiTiny.request.editor.isNotDirty=true;TWikiTiny.enableSave(true);},function(){tinyMCE.setInnerHTML(TWikiTiny.request.editor.getBody(),"<div class='twikiAlert'>"
+"There was a problem retrieving the page: "
+TWikiTiny.request.req.statusText+"</div>");});var id=editor.editorId+"_2WYSIWYG";var el=document.getElementById(id);if(el){el.style.display="none";}},saveCallback:function(editor_id,html,body){var editor=tinyMCE.getInstanceById(editor_id);for(var i=0;i<TWikiTiny.html2tml.length;i++){var cb=TWikiTiny.html2tml[i];html=cb.apply(editor,[editor,html]);}
var secret_id=tinyMCE.getParam('twiki_secret_id');if(secret_id!=null&&html.indexOf('<!--'+secret_id+'-->')==-1){html='<!--'+secret_id+'-->'+html;}
return html;},convertLink:function(url,node,onSave){if(onSave==null)
onSave=false;var orig=url;var pubUrl=TWikiTiny.getTWikiVar("PUBURL");var vsu=TWikiTiny.getTWikiVar("VIEWSCRIPTURL");url=TWikiTiny.expandVariables(url);if(onSave){if((url.indexOf(pubUrl+'/')!=0)&&(url.indexOf(vsu+'/')==0)){url=url.substr(vsu.length+1);url=url.replace(/\/+/g,'.');if(url.indexOf(TWikiTiny.getTWikiVar('WEB')+'.')==0){url=url.substr(TWikiTiny.getTWikiVar('WEB').length+1);}}}else{if(url.indexOf('/')==-1){var match=/^((?:\w+\.)*)(\w+)$/.exec(url);if(match!=null){var web=match[1];var topic=match[2];if(web==null||web.length==0){web=TWikiTiny.getTWikiVar("WEB");}
web=web.replace(/\.+/g,'/');web=web.replace(/\/+$/,'');url=vsu+'/'+web+'/'+topic;}}}
return url;},convertPubURL:function(url){var orig=url;var base=TWikiTiny.getTWikiVar("PUBURL")+'/'
+TWikiTiny.getTWikiVar("WEB")+'/'
+TWikiTiny.getTWikiVar("TOPIC")+'/';url=TWikiTiny.expandVariables(url);if(url.indexOf('/')==-1){url=base+url;}
return url;},getMetaTag:function(inKey){if(TWikiTiny.metaTags==null||TWikiTiny.metaTags.length==0){var head=document.getElementsByTagName("META");head=head[0].parentNode.childNodes;TWikiTiny.metaTags=new Array();for(var i=0;i<head.length;i++){if(head[i].tagName!=null&&head[i].tagName.toUpperCase()=='META'){TWikiTiny.metaTags[head[i].name]=head[i].content;}}}
return TWikiTiny.metaTags[inKey];},install:function(){var tmce_init=TWikiTiny.getMetaTag('TINYMCEPLUGIN_INIT');if(tmce_init!=null){eval("tinyMCE.init({"+unescape(tmce_init)+"});");return;}
alert("Unable to install TinyMCE; <META name='TINYMCEPLUGIN_INIT' is missing");}};