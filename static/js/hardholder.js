(function($) {
  var previewTimeout;
  
  function updatePreview(v) {
    $.ajax({
      success: function(res) {
        console.log(arguments);
        $('#preview').html(res);
      },
      url: '/preview?' + $.param({ definition: v })
    });
  }
  
  $('textarea.definition').live('keyup', function() {
    var value = this.value;
    if (previewTimeout) {
      clearTimeout(previewTimeout);
      delete previewTimeout;
    }
    previewTimeout = setTimeout(function() {
      updatePreview(value);
    }, 500);
  });
}(jQuery))