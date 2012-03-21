class @Play
  constructor: ->
    $('#sheet').button()
    $('#sheets .custom-roll').live('keyup', ->
      $this = $(@)
      unless _.str.isBlank($this.val())
        $this.closest('[data-toggle="buttons-radio"]').find('.active').removeClass('active')
    )
    $('#sheets .name').live('click', -> false)
    $('#sheets [data-toggle="buttons-radio"] .btn').live('click', ->
      $(@).parent('[data-toggle="buttons-radio"]').find('.custom-roll').val('')
    )
    $('#sheets .edit-sheet, #sheets .cancel-edit').live('click', ->
      $(@).closest('.sheet').toggleClass('editing')
    )
    $('.save-sheet').live('click', =>
      sheets = _.map($('#sheets form'), (form) ->
        form = $(form)
        result = {}
        result.name = form.find('.name').val()
        result.stats = _.reduce($('tbody tr', form), (memo, row) ->
          label = $('.stat', row).val()
          roll = $('.active', row).attr('data-value') or $('.custom-roll', row).val()
          if label and roll
            memo.push(label: label, roll: roll)
          memo
        , [])

        result
      )
      $.ajax(
        data:
          sheets: sheets
        dataType: 'json'
        success: =>
          @update()
        type: 'POST'
        url: '/sheets'
      )

      # $(@).closest('.tab-content').find('.display-pane, .edit-pane').toggleClass('active')
    )
    { protocol, host } = window.location
    socket = io.connect("#{protocol}//#{host}")
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
              <span class="label label-success">#{name}</span> rolled <span class="label label-info">#{stat} of 2d6#{modifier}</span>
              and got
              <span class="label label-#{status}">#{roll}</span>
            </div>
          </div>
        """)
      $('#room-contents i:eq(1)').tooltip()
    )
    $('.sheet .roll').live('click', ->
      row = $(@).closest('tr')
      name = $(@).closest('tbody').find('.name').val()
      roll = $('.active', row).attr('data-value') or $('.custom-roll', row).val()
      stat = $('.stat', row).val()
      $this = $(@)
      socket.emit('roll',
        modifier: roll
        name: name
        stat: stat
      )
      $('#messages input').focus()
    )
    joinRoom = ->
      $room = $('#room')
      if $room.length > 0
        room = $room.val()?.toLowerCase()
        socket.emit('join room', room or 'public')

        if room
          url = _.str.dasherize("/play/#{room}")
        else
          url = '/play'
        if url isnt window.location.pathname
          history.pushState?({}, '', url)

    $('#room').live('keyup blur change', ->
      _.delay(joinRoom, 1000)
    )
    socket.on('connect', joinRoom)

    $('#room-form, #sheets form').live('submit', ->
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

    $(document).ready(=>
      code = _.str.humanize(window.location.pathname.replace(/^\/play\/?/, '')).toLowerCase()
      $('#room-form input').val(code)
      $('#search').submit(->
        window.location.href = "/moves/tagged/#{$('input[type=text]', @).val().replace(/[^a-z0-9-_]/gi, '')}"
        false
      )
      @update()
    )
  update: ->
    $.ajax(
      success: (data) ->
        $('#sheets').html(data)
        $('.collapse').collapse(toggle: false, parent: '#sheets')
      type: 'GET'
      url: '/sheets'
    )
