(function() {
  var Game, Mongoose, Move, User, auth, config, cs, db, express, games, moves, server, users, _;
  express = require('express');
  server = express.createServer();
  _ = require('underscore');
  Mongoose = require('mongoose');
  cs = require('coffee-script');
  config = require('/home/node/hardholder_config').cfg;
  auth = require('connect-auth');
  db = void 0;
  server.configure(function() {
    server.use(express.bodyParser());
    server.use(express.methodOverride());
    server.use(express.static(__dirname + '/static'));
    server.use(express.cookieParser());
    server.use(express.session({
      secret: config.session_secret
    }));
    return server.use(auth([
      auth.Twitter({
        consumerKey: config.twitter_key,
        consumerSecret: config.twitter_secret
      })
    ]));
  });
  server.configure('production', function() {
    db = Mongoose.connect('mongodb://localhost/db');
    return server.listen(80);
  });
  server.configure('development', function() {
    db = Mongoose.connect('mongodb://localhost/db');
    server.use(express.errorHandler({
      dumpExceptions: true,
      showStack: true
    }));
    return server.listen(3000);
  });
  server.configure('test', function() {
    var no_listen;
    db = Mongoose.connect('mongodb://localhost/test');
    no_listen = true;
    return module.exports.server = server;
  });
  server.set('views', __dirname + '/views');
  server.set('view engine', 'jade');
  server.get('/', function(req, res) {
    return res.redirect('/moves');
  });
  users = require('./users');
  User = db.model('User');
  users.init(server, User);
  moves = require('./moves');
  Move = db.model('Move');
  moves.route(server, Move);
  games = require('./games');
  Game = db.model('Game');
  games.route(server, Game);
}).call(this);
