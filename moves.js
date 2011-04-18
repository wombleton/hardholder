var dateformat = require('dateformat'),
    flow = require('flow'),
    Mongoose = require('mongoose'),
    Schema = Mongoose.Schema,
    MoveSchema;

function slug(s) {
  return (s || '').replace(/[^a-zA-Z0-9]/g, '-').replace(/[-]+/g, '-').toLowerCase();
}

MoveSchema = new Schema({
  condition: String,
  date: {
    'default': function() {
      return new Date();
    },
    type: String,
    get: function(date) {
      return dateformat(new Date(), 'dd mmm yyyy');
    }
  },
  toplisting: Schema.ObjectId,
  listing_url: {
    type: String,
    get: function() {
      return this.url + '/listings'
    }
  },
  slug: String
});

MoveSchema.pre('save', function(next) {
  this.slug = slug(this.condition);
  next();
});
MoveSchema.virtual('url').get(function() {
  return '/moves/' + this.slug;
});
MoveSchema.virtual('listing_url').get(function() {
  return this.url + '/listings';
});

Mongoose.model('Move', MoveSchema);

module.exports.route = function(app, Move, Listing) {
  app.get('/moves', function(req, res) {
    flow.exec(
      function() {
        var query = Move.find({});
        query.desc('date');
        query.limit(10);
        query.exec(this);
      },
      function(err, moves) {
        var args = [],
            i;
        console.log(moves);
        this.moves = moves;
        if (moves.length === 0) {
          this([]);
        } else {
          for (i = 0; i < moves.length; i++) {
            Listing.findById(moves[i].toplisting, this.MULTI());
          }
        }
      },
      function(multi) {
        var i,
            listing,
            listings = {};
        for (i = 0; i < multi.length; i++) {
          listing = multi[i][1];
          if (listing) {
            listings[listing._id] = listing;
          }
        }
        res.render('moves/index', { locals: {
          moves: this.moves,
          listings: listings
        }});
      }
    );
  });

  app.post('/moves', function(req, res) {
    var move;
    Move.findOne({ slug: slug(req.body.move.condition) }, function(err, move) {
      if (!move) {
        move = new Move(req.body.move);
        move.save(function() {
          res.redirect(move.url);
        });
      } else {
        res.redirect(move.url);
      }
    });
  });

  app.get('/moves/new', function(req, res) {
    res.render('moves/new');
  });

  app.get('/moves/:id', function(req, res) {
    Move.findOne({ slug: req.params.id }, function(err, move) {
      var query = Listing.find({ 'meta.move_slug': move.slug });
      query.desc('meta.upvotes');
      query.exec(function(err, listings) {
        res.render('moves/show', {
          locals: {
            listings: listings,
            move: move
          }
        });
      });
    });
  });
};