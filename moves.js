(function() {
  var moves,
      _ = require('underscore'),
      Mongoose = require('mongoose'),
      Schema = Mongoose.Schema,
      MoveSchema;

  function slug(s) {
    return (s || '').replace(/[^a-zA-Z0-9]/, '-').replace(/[-]+/, '-');
  }

  MoveSchema = new Schema({
    condition: String,
    slug: String,
    roll: String,
    preamble: String,
    success: String,
    partial: String,
    failure: String,
    postamble: String,
    created_at: Date
  }) ;

  Mongoose.model('Move', MoveSchema);

  module.exports.route = function(app, Move) {
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
        res.redirect('/moves/' + move._id.toHexString());
      });
    });

    app.get('/moves/new', function(req, res) {
      res.render('moves/new');
    });

    app.get('/moves/:id', function(req, res) {
      Move.findOne({ slug: req.params.id }, function(err, move) {
        res.render('moves/show', {
          locals: {
            move: move,
            _: _
          }
        });
      });
    });

    app.get('/moves/:id/edit', function(req, res) {
      var id = req.params.id,
          move = Moves.find(id);
      res.render('moves/edit', {
        locals: {
          move: move,
          _: _
        }
      });
    });
  };
}());