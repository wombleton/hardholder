(function() {
  var moves,
      _ = require('underscore'),
      Mongoose = require('mongoose'),
      Schema = Mongoose.Schema,
      Move;

  Move = new Schema({
    condition: String,
    slug: String,
    roll: String,
    success: String,
    partial: String,
    failure: String,
    created_at: Date
  });

  Mongoose.model('Move', Move);
}());