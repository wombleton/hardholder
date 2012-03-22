bcrypt = require('bcrypt')
db = require('../db').db
{ Sheet } = require('./sheet')
mongoose = require('mongoose')
{ Schema } = mongoose

UserSchema = new Schema(
  facebook:
    id: String
    accessToken: String
    name:
      full: String
      first: String
      last: String
    fbAlias: String
    email: String
  login:
    type: String
    unique: true
  salt: String
  hash: String
  twitter:
    accessToken: String
    accessTokenSecret: String
    name: String
    screenName: String
    id: String
    url: String
  type: String
  sheets: [ Sheet ]
  human:
    default: false
    type: Boolean
)

UserSchema.virtual('password')
  .get(->
    @_password
  )
  .set((password) ->
    @_password = password
    @salt = bcrypt.genSaltSync(10)
    @hash = bcrypt.hashSync(password, @salt)
  )

User = mongoose.model('User', UserSchema)

module.exports.User = db.model('User')
