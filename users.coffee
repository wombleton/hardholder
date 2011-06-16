OAuth = require('oauth').OAuth
Mongoose = require('mongoose')
Schema = Mongoose.Schema
config = require('../hardholder_config').cfg

User = new Schema
  name: String
  url:
    index: true
    type: String
  profile_pic: String
  service: String
  ts:
    default: -> new Date().getTime()
    index: true
    type: Number
  
Mongoose.model 'User', User

getAuth = (req) ->
  details = req.getAuthDetails()
  user = details.user
  if user
    twitterish = user.user_id and user.username
    facebookish = user.name and user.link
  
    if twitterish
      return {
        name: user.username
        service: 'twitter'
        url: "https://twitter.com/#{user.username}"
      }
    else if facebookish
      return {
        name: user.name
        service: 'facebook'
        url: user.link
      }
  else
    return undefined

    
module.exports.init = (server, User) ->
  saveSignup = (user) ->
    usr = new User(user)
    usr.save
  
    
  server.get '/login', (req, res) ->
    if req.isAuthenticated()
      res.redirect req.session.authenticated_redirect_url
      delete req.session.authenticated_redirect_url 
    else
      res.render('users/login')
  
  server.get '/logout', (req, res) ->
    req.logout()
    res.redirect '/'
  
  server.get '/authed/twitter_callback', (req, res) -> 
    req.authenticate ['twitter'], (error, authenticated) ->
      if authenticated
        console.log 'authed'
        res.send("<html><h1>Hello Facebook user:" + JSON.stringify( req.getAuthDetails() ) + ".</h1></html>")
      else
        console.log 'not authed'
        res.send("<html><h1>Facebook authentication failed :( </h1></html>")
      
###
  server.get '/authed/twitter_callback', (req, res) ->
    req.authenticate ['twitter'], (error, authenticated) ->
      console.log req.isAuthenticated()
      console.log req.session
      if authenticated
        res.redirect req.session.twitter_redirect_url or '/'
      else
        delete req.session.twitter_redirect_url
        res.redirect '/'
###
        