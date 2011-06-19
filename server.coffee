express = require('express')
server = express.createServer()
cs = require('coffee-script')
config = require('/home/node/hardholder_config').cfg
auth = require('connect-auth')

server.configure ->
  server.use express.logger()
  server.use(express.bodyParser());
  server.use(express.methodOverride());
  server.use(express.static(__dirname + '/static'))
  server.use express.cookieParser()
  server.use express.session({ secret: config.session_secret })
  server.use auth([ 
    auth.Twitter({ consumerKey: config.twitter_key, consumerSecret: config.twitter_secret }) 
  ])

server.configure 'production', ->
  process.env.server = 'PRODUCTION'
  server.listen(80)

server.configure 'development', ->
  process.env.server = 'DEVELOPMENT'
  server.use(express.errorHandler(
    dumpExceptions: true
    showStack: true
  ));
  server.listen(3000)  

server.configure 'test', ->
  process.env.server = 'TEST'
  no_listen = true
  module.exports.server = server;

server.set('views', __dirname + '/views')
server.set('view engine', 'jade')

server.get '/', (req, res) -> res.redirect('/moves')

require './db'

require './models/account'
require './models/move'

require './controllers/account'