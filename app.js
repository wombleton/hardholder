var app = require('express').createServer();

app.set('view engine', 'jade');

app.get('/', function(req, res) {
  res.render('index');
});

var moves = require('./moves')

app.listen(3000);