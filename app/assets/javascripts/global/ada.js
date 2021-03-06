$(document).on('turbolinks:load', function setup() {
    // bind a click event to the 'skip' link
    $(".skip").click(function(event){

        // strip the leading hash and declare
        // the content we're skipping to
        var skipTo="#"+this.href.split('#')[1];

        // Setting 'tabindex' to -1 takes an element out of normal
        // tab flow but allows it to be focused via javascript
        $(skipTo).attr('tabindex', -1).on('blur focusout', function () {

            // when focus leaves this element,
            // remove the tabindex attribute
            $(this).removeAttr('tabindex');

        }).focus(); // focus on the content container
    });

    $("img").click(function(){
      var w = window.open($(this).attr('src'), '_blank', 'height=300,width=400,toolbar=0,location=0,menubar=0');
      $(w).on("load", function(){
          $("body", w.document).append('<button type="button" onclick="window.open(\'\', \'_self\', \'\'); window.close();" style="width:175px;height:175px;font-size:30px;">Close</button>');
      });
    });
});
