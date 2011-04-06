(function() {
  var moves,
      _ = require('underscore'),
      Mongoose = require('mongoose'),
      Schema = Mongoose.Schema,
      MoveSchema,
      ListingSchema;

  function slug(s) {
    return (s || '').replace(/[^a-zA-Z0-9]/g, '-').replace(/[-]+/g, '-');
  }

  ListingSchema = new Schema({
    date: Date,
    description: String,
    failure: String,
    meta: {
      upvotes: Number,
      downvotes: Number
    },
    partial: String,
    stat: String,
    success: String
  });

  ListingSchema.pre('save', function(next) {
    this.date = new Date();
    next();
  });
  ListingSchema.virtual('url').get(function() {
    return '/listings/' + this._id;
  });

  MoveSchema = new Schema({
    condition: String,
    date: Date,
    listings: [ ListingSchema ],
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
    this.date = new Date();
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
      Move.find({}, function(err, docs) {
        res.render('moves/index', { locals: {
          moves: docs
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

    app.get('/moves/:id', function(req, res) {
      Move.findOne({ slug: req.params.id }, function(err, move) {
        console.log(move.listings[0]);
        res.render('moves/show', {
          locals: {
            move: move
          }
        });
      });
    });

    app.get('/moves/:slug/edit', function(req, res) {
      var slug = req.params.slug;
      Move.find({ slug: slug }, function(err, move) {
        res.render('moves/edit', {
          locals: {
            move: move
          }
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

    app.post('/moves/:slug/listings', function(req, res) {
      var slug = req.params.slug;
      Move.findOne({ slug: slug }, function(err, move) {
        move.listings.push(req.body.listing);
        move.save(function(err) {
          if (err) {
            console.log(err);
          } else {
            res.redirect(move.url);
          }
        });
      });
    });
  };
}());