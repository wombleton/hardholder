db = require('../db').db
mongoose = require('mongoose')
Schema = mongoose.Schema

AccountSchema = new Schema
  username: String,
  profile_pic: String
  type: String
  human: 
    default: false
    type: Boolean
  admin: 
    default: false
    type: Boolean
  email: String
  ts:
    default: -> new Date().getTime()
    index: true
    type: Number
  url: String

mongoose.model 'Account', AccountSchema

module.exports.Account = db.model('Account')