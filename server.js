(function() {
  var auth, config, cs, express, server;
  express = require('express');
  server = express.createServer();
  cs = require('coffee-script');
  config = require('/home/node/hardholder_config').cfg;
  auth = require('connect-auth');
  server.configure(function() {
    server.use(express.logger());
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
    process.env.server = 'PRODUCTION';
    return server.listen(80);
  });
  server.configure('development', function() {
    process.env.server = 'DEVELOPMENT';
    server.use(express.errorHandler({
      dumpExceptions: true,
      showStack: true
    }));
    return server.listen(3000);
  });
  server.configure('test', function() {
    var no_listen;
    process.env.server = 'TEST';
    no_listen = true;
    return module.exports.server = server;
  });
  server.set('views', __dirname + '/views');
  server.set('view engine', 'jade');
  server.get('/', function(req, res) {
    return res.redirect('/moves');
  });
  module.exports.server = server;
  require('./db');
  require('./models/account');
  require('./models/move');
  require('./controllers/accounts');
  require('./controllers/moves');
}).call(this);
