module.exports = function() {
  return {
   "call" : "snapshot",
   "func" : function(page) {
     page.render('snapshots/test.png');
     currentTask++;
   }
  }
}
