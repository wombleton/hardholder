{ db } = require('../db')
mongoose = require('mongoose')
{ Schema } = mongoose

StatSchema = new Schema(
  label: String
  roll: String
)

SheetSchema = new Schema(
  name:
    type: String
    default: ''
  system:
    type: String
    default: 'AW'
  stats:
    default: []
    type: [ StatSchema ]
)

mongoose.model('Sheet', SheetSchema)
module.exports.Sheet = db.model('Sheet')
