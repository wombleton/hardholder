var express = require('express').createServer(),
    _ = require('underscore'),
    Mongoose = require('mongoose'),
    db = Mongoose.connect('mongodb://localhost/db');

express.set('views', __dirname + '/views');
express.set('view engine', 'jade');

express.get('/', function(req, res) {
  res.render('index');
});

var moves = require('./moves'),
    Moves = db.model('Move');

express.get('/moves', function(req, res) {
  Moves.find({}, function(err, docs) {
    res.render('moves/index', { locals: {
      moves: docs,
      _: _
    }});
  });
});

express.get('/moves/:id', function(req, res) {
  Moves.findOne({ slug: req.params.id }, function(err, move) {
    res.render('moves/show', {
      locals: {
        move: move,
        _: _
      }
    });
  });
  var id = req.params.id,
      move = Moves.find({ slug: id });
});

express.get('/moves/:id/edit', function(req, res) {
  var id = req.params.id,
      move = Moves.find(id);
  res.render('moves/edit', {
    locals: {
      move: move,
      _: _
    }
  });
});

express.listen(3000);