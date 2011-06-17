express = require('express')
server = express.createServer()
_ = require('underscore')
Mongoose = require('mongoose')
cs = require('coffee-script')
config = require('/home/node/hardholder_config').cfg
auth = require('connect-auth')

db = undefined

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
  db = Mongoose.connect('mongodb://localhost/db')
  server.listen(80)

server.configure 'development', ->
  db = Mongoose.connect('mongodb://localhost/db')
  server.use(express.errorHandler(
    dumpExceptions: true
    showStack: true
  ));
  server.listen(3000)  

server.configure 'test', ->
  db = Mongoose.connect('mongodb://localhost/test')
  no_listen = true
  module.exports.server = server;

server.set('views', __dirname + '/views')
server.set('view engine', 'jade')

server.get '/', (req, res) -> res.redirect('/moves')

users = require './users'
User = db.model 'User'
users.init server, User

moves = require('./moves')
Move = db.model('Move')

moves.route server, Move

games = require('./games')
Game = db.model('Game')
games.route(server, Game)