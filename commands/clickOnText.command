module.exports = function() {
  return {
   "call" : "open",
   "func" : function(page, text) {

     var val = page.evaluate(function() {
        if (typeof FeatTool == 'function') {
           btn = FeatTool.getButton('Edit this tiddler', jQuery);
           FeatTool.clickOnButton(btn);
         } else {
           console.log('FeatTool is not loaded!');
           currentTask++;
         }
       },
       function(result){
         console.log(result);
         currentTask++;
       });
    }
  }
}
