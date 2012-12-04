PEG = require('pegjs')
_ = require('underscore')

parser = PEG.buildParser("""
start
  = roll:roll modifier:integer { return { roll: roll, modifier: modifier }; }
  / roll:roll { return { dice: roll, modifier: 0 }; }
roll
  = count:integer type:type size:integer {
    var result = [];
    for (var i = 0; i < count; i++) {
      result.push(Math.floor(Math.random() * size) + 1)
    }
    return result;
  }
type
  = [dD]
integer
  = space "-" space digits:[0-9]+ { return -1 * parseInt(digits.join(''), 10); }
  / space [ + ]? space digits:[0-9]+ { return parseInt(digits.join(''), 10); }
space
  = " "*
""")

module.exports.roll = (s) ->
  try
    parsed = parser.parse(s)
    parsed.result = _.reduce(parsed.roll, (memo, die) ->
      memo + die
    , 0) + parsed.modifier
    parsed
  catch e
    console.log(e)
    return {
      error: "tried to roll '#{s}' but that looks like bad syntax"
    }
