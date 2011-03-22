(function() {
  var moves,
      _ = require('underscore');
  moves = [
    {
      condition: 'you *do something under fire*, or dig in to endure fire',
      slug: 'do-something-under-fire',
      roll: '+cool',
      success: 'you do it',
      partial: 'you flinch, hesitate, or stall: the MC can offer you a worse outcome, a hard bargain, or an ugly choice.',
      failure: 'the MC can make as hard a move as they like',
      created_at: new Date()
    },
    {
      condition: 'you *go aggro on someone*',
      slug: 'go-aggro',
      roll: '+hard',
      success: 'they have to choose: force your hand and suck it up, or cave and do what you want',
      partial: 'they can instead choose 1:\n* get the hell out of your way\n* barricade themselves securely in\ngive you something they think you want\n*back off calmly, hands where you can see\n*tell you what you want to know (or what you want to hear)',
      failure: 'the MC can make as hard a move as they like',
      created_at: new Date()
    }
  ];

  module.exports.all = function() {
    return moves;
  }

  module.exports.find = function(slug) {
    return _.detect(moves, function(move) {
      return move.slug === slug;
    });
  }
}());