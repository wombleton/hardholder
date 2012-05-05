express = require('express')
app = express.createServer()

port = process.env.PORT or 3000

app.configure('production', ->
  app.use(express.errorHandler())
)

app.configure('development', ->
  app.use(express.errorHandler(
    dumpExceptions: true
    showStack: true
  ))
)

app.configure(->
  app.set('views', "#{__dirname}/views")
  app.set('view engine', 'jade')
  app.use express.logger()
  app.use(express.bodyParser())
  app.use(express.methodOverride())
  app.use(express.static("#{__dirname}/static"))
  app.use(require('connect-assets')())
  app.use(express.cookieParser())

  app.use(express.session( secret: process.env.SESSION_SECRET ))
)

app.get('/', (req, res) ->
  res.redirect('/moves')
)

app.dynamicHelpers(
  category: (req, res) ->
    req.url?.match(/([^/]+)/g)?[0]
)

module.exports.app = app

require('./db')

require('./models/move')
require('./models/sheet')

require('./controllers/users')
require('./controllers/moves')
require('./controllers/play')
require('./controllers/sheets')

app.listen(port) unless app.settings.env is 'TEST'
console.log('hardholder.com server listening on port %d in %s mode', app.address().port, app.settings.env)
