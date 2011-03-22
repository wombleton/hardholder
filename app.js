var app = require('express').createServer(),
    _ = require('underscore');

app.set('views', __dirname + '/views');
app.set('view engine', 'jade');

app.get('/', function(req, res) {
  res.render('index');
});

var moves = require('./moves')

app.get('/moves', function(req, res) {
  res.render('moves/index', { locals: {
    moves: moves.all(),
    _: _
  }});
});

app.get('/moves/:id', function(req, res) {
  var id = req.params.id,
      move = moves.find(id);
  res.render('moves/show', {
    locals: {
      move: move,
      _: _
    }
  });
});

app.listen(3000);