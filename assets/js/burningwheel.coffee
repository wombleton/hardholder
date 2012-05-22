class @BurningWheel
  constructor: ->
    { protocol, host } = window.location
    socket = io.connect("#{protocol}//#{host}")
    socket.on('cls', ->
      $('#room-contents').html('')
    )
    socket.on('message', (data) ->
      { message, name, dice, result, roll, stat, time } = data
      successes = _.filter(dice, (d) ->
        d >= 4
      ).length
      if message
        $('#room-contents').prepend("""
          <div class="row">
            <div class="span10">
              <i class="icon-comment" title="#{time}"></i>
              <span class="label">#{name or 'Someone'}</span>
              #{message}
            </div>
          </div>
        """)
      else
        $('#room-contents').prepend("""
          <div class="row">
            <div class="span10">
              <i class="icon-retweet" title="#{time}"></i>
              <span class="label label-success">#{name or 'Someone'}</span> rolled <span class="label label-info">#{roll}</span>
              and got
               #{_.map(dice, (die) -> "<span class=\"label\">" + die + "</span>").join(' + ')}  = <span class="label label-success">#{successes} successes</span>
            </div>
          </div>
        """)
    )
    $('[data-dice]').live('click', ->
      name = $('[name=name]').val()
      roll = "#{$(@).attr('data-dice')}d6"
      $this = $(@)
      socket.emit('roll',
        roll: roll
        name: name
      )
      $('#messages input').focus()
    )
    joinRoom = ->
      $room = $('#room')
      if $room.length > 0
        room = $room.val()?.toLowerCase()
        socket.emit('join room', "bw::#{room}" or 'public')

        if room
          url = _.str.dasherize("/burningwheel/#{room}")
        else
          url = '/burningwheel'
        if url isnt window.location.pathname
          history.pushState?({}, '', url)

    $('#room').live('keyup blur change', ->
      _.delay(joinRoom, 1000)
    )
    socket.on('connect', joinRoom)

    postMessage = ->
      field = $('#messages input[name=chat]')
      socket.emit('message',
        message: field.val()
        name: $('[name=name]').val()
      )
      field.val('')
      field.focus()
    $('#messages').live('submit', ->
      postMessage()
      false
    )
    $('#messages input[name=chat]').live('keyup', (e) ->
      if e.keyCode is 13
        postMessage()
        false
    )

    $(document).ready(=>
      code = _.str.humanize(window.location.pathname.replace(/^\/burningwheel\/?/, '')).toLowerCase()
      $('#room-form input').val(code)
    )
