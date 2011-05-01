var express = require('express'),
    server = express.createServer(),
    _ = require('underscore'),
    Mongoose = require('mongoose'),
    db,
    no_listen;

server.configure(function() {
  server.use(express.logger());
  server.use(express.bodyParser());
  server.use(express.methodOverride());
  server.use(express.static(__dirname + '/static'))
});

server.configure('production', function() {
  db = Mongoose.connect('mongodb://localhost/db')
  server.listen(80);
});

server.configure('development', function() {
  db = Mongoose.connect('mongodb://localhost/db')
  server.use(express.errorHandler({
    dumpExceptions: true,
    showStack: true
  }));
  server.listen(3000);  
});

server.configure('test', function() {
  db = Mongoose.connect('mongodb://localhost/test')
  no_listen = true;
  module.exports.server = server;
})
server.set('views', __dirname + '/views');
server.set('view engine', 'jade');

server.get('/', function(req, res) {
  res.redirect('/moves');
});

var moves = require('./moves'),
    Move = db.model('Move');

Move.find().run(function(err, moves) {
  var i;
  for (i = 0; i < moves.length; i++) {
    moves[i].ts = moves[i].date.getTime();
    moves[i].save();
  }
});
moves.route(server, Move);
