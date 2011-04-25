var server = require('../server').server,
    assert = require('assert'),
    Mongoose = require('mongoose'),
    db = Mongoose.connect('mongodb://localhost/test'),
    Move = db.model('Move');

// clear all moves in db
Move.find({}, function(err, moves) {
  for (var i = 0; i < moves.length; i++) {
    moves[i].remove(function() {});
  }
});

exports['GET /'] = function(done) {
  assert.response(server, {
    url: '/'
  },
  {
    status: 302
  },
  function(res) {
    assert.eql('http://undefined/moves', res.headers.location);
  });  
}

exports['GET /moves'] = function() {
  assert.response(server, 
  {
    url: '/moves'
  },
  {
    status: 200
  },
  function(res) {
    assert.match(res.body, /<a href="\/moves\/new"/);
  });
}

exports['GET /moves/new'] = function() {
  assert.response(server,
  {
    url: '/moves/new'
  },
  {
    status: 200
  },
  function(res) {
    assert.match(res.body, /<form id="move" action="\/moves" method="POST">/);
    assert.match(res.body, /name="move\[condition\]"/);
    assert.match(res.body, /name="move\[stat\]"/);
    assert.match(res.body, /name="move\[definition\]"/);
    assert.match(res.body, /<input type="submit" value="New Move"\/>/);
  });
}

exports['POST /moves with invalid data'] = function() {
  function assertErrors(body) {
    assert.response(server,
    {
      url: '/moves',
      method: 'POST',
      body: body,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    },
    {
      status: 302
    },
    function(res) {
      assert.eql('http://undefined/moves/new', res.headers.location);
    });
  }
  assertErrors('');
  assertErrors('move[condition]');
  assertErrors('move[condition]=&move[stat]=&move[definition]=');
  assertErrors('move[condition]=a&move[stat]=b&move[definition]=');
  assertErrors('move[condition]=a&move[stat]=&move[definition]=c');
  assertErrors('move[condition]=&move[stat]=b&move[definition]=c');
}

exports['POST /moves'] = function() {
  assert.response(server,
  {
    url: '/moves',
    method: 'POST',
    data: 'move[condition]=a good move is a"scary move&move[stat]=b&move[definition]=c',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded'
    }
  },
  {
    status: 302
  },
  function(res) {
    assert.eql('http://undefined/moves/a-good-move-is-a-scary-move', res.headers.location);
    Move.findOne({ 'meta.slug': 'a-good-move-is-a-scary-move' }, function(err, move) {
      assert.eql('a-good-move-is-a-scary-move', move.meta.slug);
      assert.eql('a good move is a"scary move', move.condition);
      assert.eql('b', move.stat);
      assert.eql('<p>c</p>', move.definition);
    });
  });
}

exports['POST /moves with a condition of "new" fail'] = function() {
  assert.response(server,
  {
    url: '/moves',
    method: 'POST',
    data: 'move[condition]=new&move[stat]=b&move[definition]=c',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded'
    }
  },
  {
    status: 302
  },
  function(res) {
    assert.eql('http://undefined/moves/new', res.headers.location);
    Move.findOne({ 'meta.slug': 'new' }, function(err, move) {
      assert.isNull(move);
    });
  });  
};

exports['GET /moves/not-found returns 404'] = function() {
  assert.response(server, 
  {
    url: '/moves/not-found'
  },
  {
    status: 404
  },
  function(res) {
    assert.match(res.body, /Move not found. Do you want to <a href="\/moves\/new\?condition=not-found">create it<\/a>\?/);
  });
} 