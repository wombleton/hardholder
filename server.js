var express = require('express'),
    app = express.createServer(),
    _ = require('underscore'),
    Mongoose = require('mongoose'),
    db = Mongoose.connect('mongodb://localhost/db');

app.configure(function() {
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(express.static(__dirname + '/static'))
});

app.set('views', __dirname + '/views');
app.set('view engine', 'jade');

app.get('/', function(req, res) {
  res.render('index');
});

var moves = require('./moves'),
    Move = db.model('Move');
moves.route(app, Move);

app.listen(3000);