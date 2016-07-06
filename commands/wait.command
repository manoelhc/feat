module.exports = function() {
  return {
   "call" : "wait",
   "func" : function(page,seconds) {
     setTimeout(function(){ currentTask++; }, seconds * 1000);
   }
  }
}
