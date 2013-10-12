jQuery(function($) {
  var defaults = {
    delay:700,
    duration:200,
    showEffect:"fadeIn",
    hideEffect:"fadeOut",
    track:true,
    tooltipClass:'default',
    position: 'default',
    defaultPosition: { 
      my: "left+15 top+15", 
      at: "left bottom", 
      collision: "flipfit" 
    }
  };

  function addFeedbackClass(coords, feedback) {
    var $modal = $(this),
        horiz = feedback.horizontal,
        vert = feedback.vertical,
        className;

    /* map it to the correct position name */
    switch (vert) {
      case "bottom": vert = "top"; break;
      case "top": vert = "bottom"; break;
    }
    switch (horiz) {
      case "left": horiz = "right"; break;
      case "right": horiz = "left"; break;
    }

    className = "position-" + horiz + ' position-' + vert;

    $modal.offset(coords);

    $modal.removeClass(function (index, css) {
      return (css.match (/\position-\w+/g) || []).join(' ');
    });

    $modal.addClass(className);
  }

  $(".jqUITooltip:not(.jqInitedTooltip)").livequery(function() {
    var $this = $(this),
        opts = $.extend({}, defaults , $this.data());

    $this.addClass("jqInitedTooltip");

    opts.show = $.extend(opts.show, {
      effect: opts.showEffect,
      delay: opts.delay, 
      duration:opts.duration
    });
    opts.hide = $.extend(opts.hide, {
      effect: opts.hideEffect,
      delay: opts.delay, 
      duration:opts.duration
    });

    if (typeof(opts.theme) !== 'undefined') {
      opts.tooltipClass = opts.theme;
    }
  
    if (typeof(opts.position) === 'string') {
      switch(opts.position) {
        case "bottom": 
          opts.position = {"my":"center top", "at":"center bottom+10"}; 
          opts.track = false;
          break;
        case "top": 
          opts.position = {"my":"center bottom", "at":"center top-10"}; 
          opts.track = false;
          break;
        case "right": 
          opts.position = {"my":"left middle", "at":"right+10 middle"}; 
          opts.track = false;
          break;
        case "left": 
          opts.position = {"my":"right middle", "at":"left-10 middle"}; 
          opts.track = false;
          break;
        default: 
          opts.position = opts.defaultPosition;
      }
    }
    if (typeof(opts.position) === 'object') {
      opts.position.using = addFeedbackClass;
    }

    //console.log(opts);

    $this.tooltip(opts).on("tooltipopen", function(ev, ui) {
      if (opts.arrow) {
        ui.tooltip.prepend("<div class='ui-arrow'></div>");
      }
    });

  });
});

