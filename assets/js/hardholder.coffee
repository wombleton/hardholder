#= require socket.io
#= require jquery
#= require underscore-1.3.1
#= require bootstrap-button
#= require bootstrap-collapse
#= require bootstrap-tab
#= require bootstrap-tooltip
#= require underscore.string.min
#= require play

if /^\/play/.test(window.location.pathname)
  new Play()

$(document).ready(->
  $('#search').submit(->
    window.location.href = "/moves/tagged/#{$('input[type=text]', @).val().replace(/[^a-z0-9-_]/gi, '')}"
    false
  )
)
$('.move textarea, .move input').live('keyup', _.throttle(->
  form = $(@).parents('form')
  $.ajax(
    type: 'POST',
    data: $(form).serialize()
    success: (res) ->
      $('#preview').html(res)
      $('input[type=submit]')[0].disabled = $('.errors').length > 0
    url: '/preview'
  )
, 500))
