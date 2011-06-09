Mongoose = require('mongoose')
Schema = Mongoose.Schema

Update = new Schema
  ts:
    default: -> new Date().getTime()
    index: true
    type: Number
  raw: String
  value: String
  user: String

GameSchema = new Schema
  updates: [ Update ]  

Mongoose.model 'Game', GameSchema

module.exports.route = (server) ->
  server.get '/games/:id', (req, res) ->
    res.render 'games/show'