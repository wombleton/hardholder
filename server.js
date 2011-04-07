var express = require('express'),
    app = express.createServer(),
    _ = require('underscore'),
    Mongoose = require('mongoose'),
    db = Mongoose.connect('mongodb://localhost/db'),
    port = 80;

app.configure(function() {
  app.use(express.logger());
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(express.static(__dirname + '/static'))
});

app.configure('development', function() {
  app.use(express.errorHandler({
    dumpExceptions: true,
    showStack: true
  }));
  port = 3000;
});

app.set('views', __dirname + '/views');
app.set('view engine', 'jade');

app.get('/', function(req, res) {
  res.render('index');
});

var moves = require('./moves'),
    Listing = db.model('Listing'),
    Move = db.model('Move');
moves.route(app, Move, Listing);

app.listen(port);