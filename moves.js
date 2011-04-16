(function() {
  var moves,
      flow = require('flow'),
      Mongoose = require('mongoose'),
      Schema = Mongoose.Schema,
      MoveSchema,
      ListingSchema;

  function slug(s) {
    return (s || '').replace(/[^a-zA-Z0-9]/g, '-').replace(/[-]+/g, '-').toLowerCase();
  }

  ListingSchema = new Schema({
    date: Date,
    description: String,
    failure: String,
    meta: {
      move_slug: String,
      upvotes: Number,
      downvotes: Number
    },
    partial: String,
    stat: String,
    success: String
  });

  ListingSchema.path('date').default(function() {
    return new Date();
  });

  ListingSchema.path('meta.upvotes').default(function() {
    return 0;
  });

  ListingSchema.path('meta.downvotes').default(function() {
    return 0;
  });

  ListingSchema.virtual('url').get(function() {
    return '/listings/' + this._id;
  });

  MoveSchema = new Schema({
    condition: String,
    date: Date,
    toplisting: Schema.ObjectId,
    listing_url: {
      type: String,
      get: function() {
        return this.url + '/listings'
      }
    },
    slug: String
  });

  MoveSchema.path('date').default(function() {
    return new Date();
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

  Mongoose.model('Listing', ListingSchema);

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
            listings[listing._id] = listing;
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
          res.render('moves/move', {
            locals: {
              listings: listings,
              move: move
            }
          });
        });
      });
    });

    app.get('/moves/:slug/listings/new', function(req, res) {
      var slug = req.params.slug;
      Move.findOne({ slug: slug }, function(err, move) {
        res.render('listings/new', {
          locals: {
            move: move
          }
        });
      });
    });

    function updateTopListing(slug) {
      var query = Listing.find({ 'meta.move_slug': slug });
      query.desc('meta.upvotes');
      query.limit(1);
      query.exec(function(err, listings) {
        var listing = listings[0];
        if (listing) {
          if (!err && listing) {
            Move.findOne({ slug: slug }, function(err, move) {
              move.toplisting = listing._id;
              move.save();
            })
          }
        }
      });
    }

    app.post('/moves/:slug/listings', function(req, res) {
      var listing,
          slug = req.params.slug;
      Move.findOne({ slug: slug }, function(err, move) {
        listing = new Listing(req.body.listing);
        listing.meta.move_slug = move.slug;
        listing.save(function(err) {
          if (err) {
            console.log(err);
          } else {
            updateTopListing(slug);
            res.redirect(move.url);
          }
        });
      });
    });

    app.get('/listings/:id/up', function(req, res ) {
      var id = req.params.id;
      Listing.findById(id, function(err, listing) {
        listing.meta.upvotes++;
        listing.save(function() {
          updateTopListing(listing.meta.move_slug);
          res.redirect('/moves/' + listing.meta.move_slug);
        });
      });
    });
    app.get('/listings/:id/down', function(req, res ) {
      var id = req.params.id;
      Listing.findById(id, function(err, listing) {
        listing.meta.downvotes++;
        listing.save(function() {
          updateTopListing(listing.meta.move_slug);
          res.redirect('/moves/' + listing.meta.move_slug);
        });
      });
    });
  };
}());