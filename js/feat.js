function FeatTool {
}
FeatTool.prototype.getButton = function(title, jQuery) {
  buttons = [
    "button[title='%s']",
    "input[value='%s']",
    "a[title='%s']",
    "a[alt='%s']",
    "img[title='%s']",
    "img[alt='%s']"
  ];
  for(i in buttons) {
    selector = buttons[i].replace('%s', title.replace("'","\\'"));
    tmp = jQuery(selector);
    if (tmp.length > 0) {
      jQuery(document.body).append('<p>' + selector + '</p>')
      return tmp;
    }
  }
  return null;
};
FeatTool.prototype.clickOnButton = function($e) {
  $e.each(function(i,o){
    document.elementFromPoint(o.offsetLeft, o.offsetTop).click();
  });
}
