{ config, app } = require('../app')
everyauth = require('everyauth')
Account = require('../models/account').Account
Recaptcha = require('recaptcha').Recaptcha

everyauth.everymodule.findUserById((id, callback) ->
  Account.findOne(username: id, (err, account) ->
    if account
      callback(account)
    else
      account = new Account(auth)
      account.save((err)->
        callback(account)
      )
  )
)

getAuth = (req) ->
  details = req.getAuthDetails()
  user = details.user
  if user
    twitterish = user.user_id and user.username
    facebookish = user.name and user.link

    if twitterish
      return {
        username: user.username
        service: 'twitter'
        url: "https://twitter.com/#{user.username}"
      }
    else if facebookish
      return {
        username: user.name
        service: 'facebook'
        url: user.link
      }
  else
    return undefined

loadAccount = (req, cb) ->
  auth = getAuth(req)
  Account.findOne
    username: auth.username
  , (err, account) ->
    if account
      cb(account)
    else
      account = new Account(auth)
      account.save (err)->
        cb(account)

saveSignup = (user) ->
  usr = new User(user)
  usr.save

app.get '/login', (req, res) ->
  if req.isAuthenticated()
    res.redirect req.session.authenticated_redirect_url or '/'
    delete req.session.authenticated_redirect_url
  else
    res.render('users/login')

app.get '/logout', (req, res) ->
  req.logout()
  res.redirect '/'

handleAuthenticated = (req, res) ->
  loadAccount req, (account) ->
    console.log account
    if account.human
      res.redirect req.session.authenticated_redirect_url or '/'
      delete req.session.authenticated_redirect_url
    else
      res.redirect '/auth/captcha'

app.get('/auth/captcha', (req, res) ->
  if req.isAuthenticated()
    recaptcha = new Recaptcha(config.captcha_public, config.captcha_secret)
    res.render('users/recaptcha',
      locals:
        recaptcha_form: recaptcha.toHTML()
    )
  else
    res.redirect('/login')
)

app.post('/auth/captcha', (req, res) ->
  if req.loggedIn
    data =
      remoteip: req.connection.remoteAddress
      challenge: req.body.recaptcha_challenge_field
      response:  req.body.recaptcha_response_field
    recaptcha = new Recaptcha(config.captcha_public, config.captcha_secret, data)
    recaptcha.verify((success, error_code) ->
      if success
        loadAccount(req, (account) ->
          account.human = true
          account.save((err) ->
            handleAuthenticated(req, res)
          )
        )
      else
        res.render('users/recaptcha',
          locals:
            recaptcha_form: recaptcha.toHTML()
        )
    )
  else
    res.redirect('/login')
)
