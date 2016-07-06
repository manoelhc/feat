module.exports = function() {
  return {
    "call" : "open",
    "func" : function(page, url) {
      return page.open(url, function(status) {
        if (status !== 'success') {
          console.log(status);
          console.log('Unable to access network');
        } else {

          var files = 0;

          page.injectJs('js/jquery.js', function() {
            test = function() {
              return typeof jQuery || "Laws"
            };
            page.evaluate(test, function() {
              setTimeout(function(){
                files++;
                if (files == 2) {
                  currentTask++;
                }
              }, 4000);
            });
          });
          page.injectJs('js/feat.js', function(){
            test = function() {
              return typeof jQuery || "Laws"
            }
            page.evaluate(test, function() {
              setTimeout(function(){
                files++;
                if (files == 2) {
                  currentTask++;
                }
              }, 4000);
            });
          });
        }
      });
   }
  }
}
