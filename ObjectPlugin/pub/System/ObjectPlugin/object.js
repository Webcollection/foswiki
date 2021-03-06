(function($) {  
var $objectDropbox;
$.fn.initObject = function() {
	return this.each(function(){
		var $object = $(this);
		$(this).find("div.object-content").hide();
		$(this).find("div.minimize-object").click(function () { 
			$(this).hide();       	
			$object.children("div.object-content:first").slideUp();
			$(this).siblings("div.maximize-object").css({"display":"inline"});
		}).hide();
		$(this).find("div.maximize-object").click(function () {  
			$(this).hide();  	 	
			$object.children("div.object-content:first").slideDown();
			$(this).siblings("div.minimize-object").css({"display":"inline"});
		}).css({"display":"inline"}); 
		$(this).draggable({
			revert: true,
			handle: "div.object-drag-handle"
		});
		$(this).find('div.move-object').click(function(){
			if (!$objectDropbox) {
				foswiki.HijaxPlugin.serverAction({
					type: "GET",
					async: false,
					url: foswiki.scriptUrl+'/rest/RenderPlugin/tag', 
					data: {
						name: 'INCLUDE',
						param: foswiki.systemWebName+'/ObjectModules',
						section: 'dropbox',
						render: 1
					}, 
					dataType: "html",
					cache: false, 
					success: function(html) {
						$objectDropbox = $(html).dialog({
							bgiframe: true,
							autoOpen: false,
							show: 'blind',
							height: '500',
							width: '600px'
						});
					}
				});
			}
			$objectDropbox.dialog('open');
			return false;
		});
		$(this).find('div.delete-object').click(function(){
			var $controls = $object.find('.object-controls:first');
			var message = "Delete: "+$object.find('div.object-title:first').html().replace(/<.*?>/g,'')+" ?";
			var del = confirm(message);
			if (del) {
				foswiki.HijaxPlugin.serverAction({
					url: foswiki.scriptUrl+'/rest/ObjectPlugin/move',
					type: 'GET',
					$object: $object,
					success: function() {
						this.$object.remove();
					},
					data: {
						uid: $object.attr('id'),
						topic: $controls.attr('web')+'.'+$controls.attr('topic'),
						target: 'Trash.TrashObject',
						cover: 'ajax',
						asobject: 1
					}
				});
			}
		});
		if (!($.browser.msie && /6.0/.test(navigator.userAgent) )) {
			// for some reason IE6 freezes up if this is allowed
			// can't be bothered to figure out why
			$(this).find('div.edit-object a').click(function(){
				var myURL = foswiki.HijaxPlugin.parseURL(this.href);
				var url = this.href.replace(myURL.query,'');
				myURL.params.cover = 'object,ajax';
				var data = myURL.params;
				foswiki.HijaxPlugin.serverAction({
					url: url,
					type: 'GET',
					data: data,
					loading: $object.get(0),
					success: function(json){
						var $content = $('<div class="object-container rounded shadow"></div>');
						$object.replaceWith($content);
						foswiki.HijaxPlugin.loadContent(json,$content);
						var cdata = data;
						var curl = url
						$('#cancel'+data.uid).click(function(){
							cdata.context = 'view';
							foswiki.HijaxPlugin.serverAction({
								url: curl,
								type: 'GET',
								data: cdata,
								loading: $content.get(0),
								success: function(json){
									foswiki.HijaxPlugin.loadContent(json,$content,'replaceWith')
										.find('div.object-container')
										.initObject().find("div.maximize-object").click();
								}
							});
							return false;
						});
						var $form = $('#editObject'+data.uid);
						$form.find('input[type="submit"]').click(function(){
							var sdata = foswiki.HijaxPlugin.asObject($form
															.find('input,select,textarea')
															.not('[name="redirectto"]'));
							var surl = $form.attr('action');
							foswiki.HijaxPlugin.serverAction({
								url: surl,
								data: sdata,
								loading: $content.get(0),
								success: function(json){
									foswiki.HijaxPlugin.loadContent(json,$content,'replaceWith')
										.find('div.object-container')
										.initObject().find("div.maximize-object").click();
								}
							});
							return false;
						});
					}
				});
				return false;
			});
		}
    });
};
foswiki.ObjectPlugin = function(){
var $objectDialog;
return {
newObject : function(type,oweb,otopic,insertpos) {
	if (!insertpos) insertpos = 'prepend';
    foswiki.HijaxPlugin.serverAction({
        type: 'GET',
        url: foswiki.scriptUrl+'/rest/ObjectPlugin/view',
		data: {
			topic: oweb+'.'+otopic,
			type: type,
			cover: 'object,ajax',
			context: 'edit'
		},
        success: function(json) {
			$objectDialog = $('<div>'+json.content+'</div>').dialog({width:'auto'});
			$objectDialog.find('#save').click(function(){
				var $form = $(this).parents('form:first');
				var data = foswiki.HijaxPlugin.asObject($form.find('input,select,textarea')
															.not('input[name="redirectto"]')
															.add('<input name="insertpos" value="'+insertpos+'">'));
				var url = $form.attr('action');
				foswiki.HijaxPlugin.serverAction({
					url: url,
					data: data,
					success: function(json) {
						foswiki.HijaxPlugin.loadContent(json,$('#objectsObject'),insertpos);
						$objectDialog.remove();
					}
				});
				return false;
			}).siblings('a').click(function(){$objectDialog.remove(); return false;});
        }
    });
}
};
}();
})(jQuery);