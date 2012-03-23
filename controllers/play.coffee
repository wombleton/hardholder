{ app } = require('../app')
_ = require('underscore')
_s = require('underscore.string')
countdown = require('countdown')

app.get('/play', (req, res) ->
  res.render('play/index')
)
app.get('/play/:id', (req, res) ->
  res.render('play/index')
)

io = require('socket.io').listen(app)

d6 = ->
  Math.floor(Math.random() * 6) + 1

cache = {}

reap = ->
  now = new Date().getTime()
  _.each(cache, (room, key) ->
    if room.lastUpdated < now - 24 * 60 * 60 * 1000
      delete cache[key]
  )

setInterval(reap, 60 * 60 * 1000)

timestamp_message = (message) ->
  timestamp = countdown(message.ts, new Date().getTime(), countdown.HOURS | countdown.MINUTES | countdown.SECONDS)
  if _s.isBlank(timestamp)
    message.time = 'Just now'
  else
    message.time = "#{timestamp} ago"
  message

addMessage = (room, message) ->
  cache[room] ?=
    messages: []
  rm = cache[room]
  rm.lastUpdated = message.ts = new Date().getTime()
  rm.messages.push(message)
  while rm.messages.length > 256
    rm.messages.shift()
  timestamp_message(message)

io.sockets.on('connection', (socket) ->
  socket.on('join room', (room) ->
    socket.set('room', room)
    socket.join(room)
    socket.emit('cls')
    cached_messages = cache[room]?.messages
    _.each(cached_messages, (message) ->
      socket.emit('message', timestamp_message(message))
    )
  )
  socket.on('roll', (data) ->
    { stat, name, roll } = data
    result = d6() + d6()
    socket.get('room', (err, room) ->
      io.sockets.in(room).emit('message', addMessage(room,
        roll: roll
        name: name
        result: result
        stat: stat
      ))
    )
  )
  socket.on('message', (data) ->
    { name, message } = data
    message = _s.trim(_s.stripTags(message))
    unless _s.isBlank(message)
      socket.get('room', (err, room) ->
        io.sockets.in(room).emit('message', addMessage(room,
          message: message
          name: name
        ))
      )
  )
)
