{ app } = require('../app')
_ = require('underscore')
_s = require('underscore.string')
countdown = require('countdown')
PEG = require('pegjs')

parser = PEG.buildParser("""
start
  = roll:roll modifier:integer { return { roll: roll, modifier: modifier }; }
  / roll:roll { return { roll: roll, modifier: 0 }; }
roll
  = count:integer type:type size:integer {
    var result = [];
    for (var i = 0; i < count; i++) {
      result.push(Math.floor(Math.random() * size) + 1)
    }
    return result;
  }
type
  = [dD]
integer
  = space "-" space digits:[0-9]+ { return -1 * parseInt(digits.join(''), 10); }
  / space [ + ]? space digits:[0-9]+ { return parseInt(digits.join(''), 10); }
space
  = " "*
""")

app.get('/play', (req, res) ->
  res.render('play/index')
)
app.get('/play/:id', (req, res) ->
  res.render('play/index')
)

io = require('socket.io').listen(app)
io.configure(->
  io.set('transports', ['xhr-polling'])
  io.set('polling duration', 10)
)

dx = (d) ->
  Math.floor(Math.random() * Number(d)) + 1

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
    try
      parsed = parser.parse(roll)
      result = _.reduce(parsed.roll, (memo, roll) ->
        memo + roll
      , 0) + parsed.modifier

      socket.get('room', (err, room) ->
        io.sockets.in(room).emit('message', addMessage(room,
          custom: parsed.custom
          dice: parsed.roll
          roll: roll
          name: name
          result: result
          stat: stat
        ))
      )
    catch e
      socket.get('room', (err, room) ->
        io.sockets.in(room).emit('message',
          name: name
          message: "tried to roll #{roll} but that looks like bad syntax. 2d6 is an example that will work."
        )
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
