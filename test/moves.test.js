var server = require('../server').server,
    assert = require('assert');

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

exports['POST /moves with invalid'] = function() {
  assert.response(server,
  {
    url: '/moves',
    method: 'POST'
  },
  {
    status: 302
  });
}