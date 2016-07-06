module.exports = function() {
  return {
    "call" : "open",
    "func" : function(page, selector) {

       var fn = function() {

       var code = '(function() {' +
          "el = jQuery('" + selector.replace("'", "\\'") + "').first();" +
          'return el;' +
          'if (el === null) return false;' +
          'var style = window.getComputedStyle(el);' +
          'return (style.display !== "none") && (el.offsetParent !== null);})';

        code = '(function(){return document'

        var val = page.evaluate(function() {
          return true;
        });

        console.log(val);

        if(val === true) {
          currentTask++;
          clearInterval(pid);
        }
      }
      var pid = setInterval(fn, 1000); 

    }
  }
}
