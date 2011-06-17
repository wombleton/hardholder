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
    
loadAccount = (req,loadCallback) ->
  console.log req.getAuthDetails().user
  loadCallback(null)

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
  
  # Auth Routes
  server.get '/auth/twitter', (req,res) ->
    unless req.query.denied
      req.authenticate ['twitter'], (error, authenticated) ->
        loadAccount req, (account) ->
          if req.query.oauth_token and req.query.oauth_verifier
            console.log res._headers
            res.redirect req.session.authenticated_redirect_url or '/'
            delete req.session.authenticated_redirect_url
          else
            console.log 'continuing ...'
    else
      console.log 'denying'
      res.redirect('/')          
      