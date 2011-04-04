(function($) {
  $('.expando').live('click', function() {
    $(this).parent().removeClass('collapsed').addClass('expanded');
    return false;
  });
}(jQuery))