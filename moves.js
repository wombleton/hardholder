var dateformat = require('dateformat'),
    flow = require('flow'),
    md = require('node-markdown').Markdown,
    MD_TAGS = 'b|blockquote|code|del|dd|dl|dt|em|h1|h2|h3|i|img|li|ol|p|pre|sup|sub|strong|strike|ul|br|hr',
    Mongoose = require('mongoose'),
    Schema = Mongoose.Schema,
    MoveSchema;

function slug(s) {
  return (s || '').replace(/[^a-zA-Z0-9]/g, '-').replace(/[-]+/g, '-').toLowerCase();
}

MoveSchema = new Schema({
  condition: String,
  definition: {
    get: function(defn) {
       return md(defn, MD_TAGS);
    },
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
    type: String,
    get: function(date) {
      return dateformat(new Date(), 'dd mmm yyyy');
    }
  }
});

MoveSchema.pre('save', function(next) {
  this.meta.slug = slug(this.condition);
  next();
});
MoveSchema.virtual('url').get(function() {
  return '/moves/' + this.meta.slug;
});
MoveSchema.virtual('definition_url').get(function() {
  return '/moves/' + this.meta.slug  + '/' + this._id;
});

Mongoose.model('Move', MoveSchema);

module.exports.route = function(app, Move) {
  app.get('/moves', function(req, res) {
    var query = Move.find({});
    query.desc('date');
    query.limit(10);
    query.exec(function(err, moves) {
      res.render('moves/index', { locals: {
        moves: moves
      }});
    });
  });

  app.post('/moves', function(req, res) {
    var move = new Move(req.body.move);
    move.save(function() {
      res.redirect(move.url);
    });
  });

  app.get('/moves/new', function(req, res) {
    res.render('moves/new');
  });

  app.get('/moves/:slug', function(req, res) {
    var query = Move.find({ 'meta.slug': req.params.slug });
    query.desc('meta.upvotes');
    query.exec(function(err, moves) {
      res.render('moves/show', {
        moves: moves
      });
    });
  });
  
  app.post('/preview', function(req, res) {
    res.send(md(req.body.definition || '', MD_TAGS));
  });

  app.get('/moves/:id/up', function(req, res) {
    flow.exec(
      function() {
        Move.findById(req.params.id, this);
      },
      function(err, move) {
        move.meta.upvotes++;
        move.save(this);
      },
      function(err) {
        res.redirect(move.url);
      }
    );
  });
  
  app.get('/moves/:id/down', function(req, res) {
    flow.exec(
      function() {
        Move.findById(req.params.id, this);
      },
      function(err, move) {
        move.meta.downvotes++;
        move.save(this);
      },
      function(err) {
        res.redirect(move.url);
      }
    );
  });
};