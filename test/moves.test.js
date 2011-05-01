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
    assert.match(res.body, /<form action="\/moves" method="POST" class="move">/);
    assert.match(res.body, /name="move\[condition\]"/);
    assert.match(res.body, /name="move\[authors\]"/);
    assert.match(res.body, /name="move\[source\]"/);
    assert.match(res.body, /name="move\[definition\]"/);
    assert.match(res.body, /<input type="submit" value="Save" class="save"\/>/);
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
  assertErrors('move[condition]=a&move[definition]=');
  assertErrors('move[condition]=&move[definition]=On a 7-9 On a 10%2b');
  assertErrors('move[condition]=&move[definition]=roll%2bhot');
  assertErrors('move[condition]=a&move[definition]=c');
}

exports['POST /moves'] = function() {
  assert.response(server,
  {
    url: '/moves',
    method: 'POST',
    data: 'move[condition]=a good move is a"scary move&move[definition]=On a 7 - 9 On a 10%2b roll%2bhot',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded'
    }
  },
  {
    status: 302
  },
  function(res) {
    assert.eql('http://undefined/moves/a-good-move-is-ascary-move', res.headers.location);
    Move.findOne({ 'meta.slug': 'a-good-move-is-ascary-move' }, function(err, move) {
      assert.eql('a-good-move-is-ascary-move', move.meta.slug);
      assert.eql('a good move is a"scary move', move.condition);
      assert.eql('hot', move.stat);
      assert.eql('<p>On a 7 - 9 On a 10+ roll+hot</p>', move.definition_markdown);
      assert.eql('On a 7 - 9 On a 10+ roll+hot', move.definition);
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

exports['GET /moves/my-move/edit'] = function() {
  Move.findOne({}, function(err, move) {
    assert.response(server,
    {
      url: move.edit_url
    },
    {
      status: 200
    });
  });
}
