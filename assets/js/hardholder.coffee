#= require socket.io
#= require jquery
#= require underscore-1.3.1
#= require bootstrap-button
#= require bootstrap-collapse
#= require bootstrap-tab
#= require bootstrap-tooltip
#= require underscore.string.min

$('#sheet').button()
$('.collapse').collapse(
  toggle: false
)
$('#sheets .edit-sheet, #sheets .cancel-edit').live('click', ->
  $(@).parents('.tab-content').find('.display-pane, .edit-pane').toggleClass('active')
)
$('#sheets .save-sheet').live('click', ->
  $(@).parents('.tab-content').find('.display-pane, .edit-pane').toggleClass('active')
)

socket = io.connect('http://localhost')
socket.on('cls', ->
  $('#room-contents').html('')
)
socket.on('message', (data) ->
  { message, modifier, name, roll, stat, time } = data
  if roll >= 10
    status = 'success'
  else if 7 <= roll <= 9
    status = 'info'
  else
    status = 'important'
  if message
    $('#room-contents').prepend("""
      <div class="row">
        <div class="span7">
          <i class="icon-comment" title="#{time}"></i>
          <span class="label">#{name}</span>
          #{message}
        </div>
      </div>
    """)
  else
    $('#room-contents').prepend("""
      <div class="row">
        <div class="span7">
          <i class="icon-retweet" title=#{time}></i>
          <span class="label label-success">#{name}</span>
          rolled
          <span class="label label-info">#{stat} of 2d6#{modifier}</span>
          and got
          <span class="label label-#{status}">#{roll}</span>
        </div>
      </div>
    """)
  $('#room-contents i:eq(1)').tooltip()
)
$('.dice .die').live('click', ->
  $this = $(@)
  socket.emit('roll',
    modifier: $this.attr('data-modifier')
    name: $this.parents('.accordion-group').find('h3').html()
    stat: $this.attr('data-stat')
  )
  $('#messages input').focus()
)
joinRoom = ->
  socket.emit('join room', $('#room').val()?.toLowerCase() or 'public')


$('#room').live('keyup blur change', ->
  _.delay(joinRoom, 1000)
)
socket.on('connect', joinRoom)

$('#room-form').live('submit', ->
  false
)

postMessage = ->
  field = $('#messages input')
  socket.emit('message',
    message: field.val()
    name: $('.accordion-body.in').parent('.accordion-group').find('h3').html()
  )
  field.val('')
  field.focus()
$('#messages').live('submit', ->
  postMessage()
  false
)
$('#messages input').live('keyup', (e) ->
  if e.keyCode is 13
    postMessage()
    false
)

$(document).ready(->
  code = _.str.humanize(window.location.pathname.replace(/^\/game\//, ''))
  $('#room-form input').val(code)
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
