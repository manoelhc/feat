module.exports = function() {
  return {
    "call" : "resize",
    "func" : function(page, width, height) {
      page.set('viewportSize', { width: width, height: height });
      page.set('paperSize', { width: width, height: height });
      currentTask++;
    }
  }
}
