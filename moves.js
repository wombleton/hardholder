var dateformat = require('dateformat'),
    flow = require('flow'),
    md = require('node-markdown').Markdown,
    MD_TAGS = 'b|em|i|li|ol|p|strong|ul|br|hr',
    Mongoose = require('mongoose'),
    Schema = Mongoose.Schema,
    _ = require('underscore'),
    MoveSchema;

function slug(s) {
  return (s || '').replace(/[^a-zA-Z0-9]/g, '-').replace(/[-]+/g, '-').toLowerCase();
}

MoveSchema = new Schema({
  condition: {
    'default': '',
    type: String,
    validate: [
      function(v) {
        return (v || '').match(/\w/)
      },
      'empty'
    ]
  },
  definition: {
    type: String
  },
  meta: {
    downvotes: {
      type: Number,
      'default': 0
    },
    slug: String,
    upvotes: {
      type: Number,
      'default': 0
    }
  },
  date: {
    'default': function() {
      return new Date();
    },
    index: true,
    type: String,
    get: function(date) {
      return dateformat(date, 'dd mmm yyyy');
    }
  },
  stat: {
    type: String
  },
  authors: String,
  source: String
});

MoveSchema.pre('save', function(next) {
  this.meta.slug = slug(this.condition);
  next();
});
MoveSchema.virtual('url').get(function() {
  return '/moves/' + this.meta.slug;
});

MoveSchema.virtual('definition_markdown').get(function() {
  return md(this.definition || '', MD_TAGS);
});

MoveSchema.virtual('edit_url').get(function() {
  return '/moves/' + this._id + '/edit';
});

MoveSchema.virtual('definition_url').get(function() {
  return '/moves/' + this.meta.slug  + '/' + this._id;
});
MoveSchema.virtual('id_url').get(function() {
  return '/moves/' + this._id;
});

Mongoose.model('Move', MoveSchema);

function validate(move) {
  var condition = move.condition || '',
      stat,
      definition = move.definition || '',
      roll,
      errors = [];
  
  roll = definition.match(/roll\s?[+]\s?(\w+)/i);
  move.stat = stat = (roll && roll[1]) || '';
  
  if (condition.match(/^\s*new\s*$/)) {
    errors.push('Title cannot be "new".');
  }
  if (!condition.match(/\w/)) {
    errors.push('Title cannot be blank.');
  }
  if (!stat.match(/\w/)) {
    errors.push('Definition must include what to roll, such as "roll +hot".');    
  }
  if (!definition.match(/On\s+(a\s+)?7\s?-\s?9/i)) {
    errors.push('Definition must include "on a 7-9".');
  }
  if (!definition.match(/On\s+(a\s+)?10[+]/i)) {
    errors.push('Definition must include "On 10+".')
  }
  return errors;
}

module.exports.route = function(server, Move) {
  server.get('/moves', function(req, res) {
    var query = Move.find()
      .desc('date')
      .limit(50)
      .run(function(err, moves) {
        res.render('moves/index', { locals: {
          moves: moves
        }});
    });
  });

  server.post('/moves', function(req, res) {
    var move = new Move(req.body && req.body.move),
        errors = validate(move);
    if (errors.length === 0) {
      move.save(function(err) {
        if (err) {
          res.redirect('/moves/new');
        } else {
          res.redirect(move.url);
        }
      });
    } else {
      res.redirect('/moves/new');
    }
  });

  server.post('/moves/:id', function(req, res) {
    Move.findById(req.params.id, function(err, move) {
      move = _.extend(move, req.body.move);
      move.save(function(err) {
        if (err) {
          res.render('moves/edit', {
            locals: {
              move: move
            }
          });
        } else {
          res.redirect(move.url);
        }
      });
    });
  });
  
  server.get('/moves/new', function(req, res) {
    res.render('moves/new', {
      locals: {
        context: 'new'
      }
    });
  });

  server.get('/moves/:slug', function(req, res) {
    var query = Move.find({ 'meta.slug': req.params.slug });
    query.desc('meta.upvotes');
    query.exec(function(err, moves) {
      if (moves.length === 0) {
        res.render('404', {
          locals: {
            condition: req.params.slug
          },
          status: 404 
        });
      } else {
        res.render('moves/index', {
          moves: moves
        });
      }
    });
  });
  
  server.post('/preview', function(req, res) {
    var move = new Move(req.body.move),
        errors = validate(move);

    res.render('moves/preview', {
      layout: false,
      locals: {
        errors: errors,
        move: move
      }
    })
  });

  server.get('/moves/:id/up', function(req, res) {
    flow.exec(
      function() {
        Move.findById(req.params.id, this);
      },
      function(err, move) {
        move.meta.upvotes++;
        this.move = move;
        move.save(this);
      },
      function(err) {
        res.redirect(req.headers.referer);
      }
    );
  });
  
  server.get('/moves/:id/down', function(req, res) {
    flow.exec(
      function() {
        Move.findById(req.params.id, this);
      },
      function(err, move) {
        move.meta.downvotes++;
        this.move = move;
        move.save(this);
      },
      function(err) {
        res.redirect(req.headers.referer);
      }
    );
  });

  server.get('/moves/:id/edit', function(req, res) {
    Move.findById(req.params.id, function(err, move) {
      console.log(move);
      res.render('moves/edit.jade', {
        locals: {
          move: move
        }
      });        
    });
  });
};
