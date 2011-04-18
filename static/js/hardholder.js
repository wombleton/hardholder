(function($) {
  var previewTimeout;
  
  function updatePreview(v) {
    $.ajax({
      type: 'POST',
      data: {
        definition: v
      },
      success: function(res) {
        $('#preview').html(res);
      },
      url: '/preview'
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