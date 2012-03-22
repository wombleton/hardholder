{ app, config } = require('../app')
bcrypt = require('bcrypt')
{ User } = require('../models/user')
mongoose = require('mongoose')
{ Schema } = mongoose
everyauth = require('everyauth')
Recaptcha = require('recaptcha').Recaptcha

{ captcha_public, captcha_secret, session_secret, twitter_key, twitter_secret, facebook_id, facebook_secret, facebook_callback } = config

everyauth.everymodule.findUserById((userId, callback) ->
  console.log('find user by id called')
  User.findById(userId, (err, user) ->
    if err
      callback(err, null)
    else
      callback(null, user)
  )
)

everyauth.password
  .loginWith('login')
  .getLoginPath('/login')
  .postLoginPath('/login')
  .loginView('login.jade')
  .authenticate((login, password) ->
    errors = []
    errors.push('Missing login.') unless login
    errors.push('Missing password.') unless password
    if errors.length
      errors
    else
      promise = @Promise()
      User.findOne('login': login, (err, user) ->
        if err
          promise.fulfill([ err.message or err ])
        else if user
          bcrypt.compare(password, user.hash, (err, success) ->
            if success
              promise.fulfill(user)
            else
              promise.fulfill([ 'That username and password combination is invalid.' ])
          )
        else
          promise.fulfill([ 'That username and password combination is invalid.' ])
      )
      promise
  )
  .getRegisterPath('/login')
  .postRegisterPath('/register')
  .registerView('login.jade')
  .validateRegistration((attrs, errors) ->
    promise = @Promise()
    user = new User(attrs)
    user.validate((err) ->
      if err
        errors.push(err.message or err)
      if errors.length
        promise.fulfill(errors)
      else
        promise.fulfill(null)
    )
    promise
  )
  .registerUser((attrs) ->
    promise = @Promise()
    User.create(attrs, (err, createdUser) ->
      if err
        if /duplicate key/.test(err)
          promise.fulfill([ 'Someone has already claimed that login.' ])
        else
          promise.fulfill(err)
      else
        promise.fulfill(createdUser)
    )
    promise
  )
  .loginSuccessRedirect('/auth/captcha')
  .registerSuccessRedirect('/auth/captcha')

everyauth.twitter
  .consumerKey(twitter_key)
  .consumerSecret(twitter_secret)
  .findOrCreateUser((sess, accessToken, accessSecret, twitUser) ->
    promise = @Promise()
    User.findOne('twitter.id': twitUser.id, (err, user) ->
      if err
        promise.fulfill([err.message or err])
      else if user
        promise.fulfill(user)
      else
        { id, name, screen_name, url } = twitUser
        user =
          twitter:
            accessToken: accessToken
            accessTokenSecret: accessSecret
            id: id
            screenName: screen_name
            name: name
            url: url

        User.create(user, (err, createdUser) ->
          promise.fulfill(createdUser)
        )
    )
    promise
  )
  .redirectPath('/auth/captcha')

everyauth.facebook
  .appId(facebook_id)
  .appSecret(facebook_secret)
  .findOrCreateUser((sess, accessToken, accessTokenExtra, fbUser) ->
    promise = @Promise()
    User.findOne('facebook.id': fbUser.id, (err, user) ->
      if err
        promise.fail(err)
      else if user
        promise.fulfill(user)
      else
        { expires } = accessTokenExtra
        expiresDate = new Date()
        expiresDate.setSeconds(expiresDate.getSeconds() + expires)
        { email, first_name, id, last_name, link, name } = fbUser
        user =
          facebook:
            id: id
            accessToken: accessToken
            expires: expiresDate
            name:
              full: name
              first: first_name
              last: last_name
            fbAlias: link.match(/^http:\/\/www.facebook\.com\/(.+)/)?[1]
            email: email
        User.create(user, (err, createdUser) ->
          promise.fulfill(createdUser)
        )
        promise
    )
  )
  .redirectPath('/auth/captcha')

app.use(everyauth.middleware())
everyauth.helpExpress(app)

app.get('/auth/captcha', (req, res) ->
  { userId } = req.session.auth
  if userId
    everyauth.everymodule._findUserById(userId, (err, user) ->
      if user.human
        res.redirect('/')
      else
        recaptcha = new Recaptcha(captcha_public, captcha_secret)
        res.render('users/recaptcha',
          locals:
            recaptcha_form: recaptcha.toHTML()
        )
    )
  else
    req.session.auth = null
    res.redirect('/')
)

app.post('/auth/captcha', (req, res) ->
  { loggedIn, userId } = req.session.auth
  if loggedIn
    data =
      remoteip: req.connection.remoteAddress
      challenge: req.body.recaptcha_challenge_field
      response:  req.body.recaptcha_response_field
    recaptcha = new Recaptcha(config.captcha_public, config.captcha_secret, data)
    recaptcha.verify((success, error_code) ->
      if success
        User.update({ _id: userId }, { $set: { human: true } }, {}, (err) ->
          res.redirect('/')
        )
      else
        res.render('users/recaptcha',
          locals:
            recaptcha_form: recaptcha.toHTML()
        )
    )
  else
    res.redirect('/')
)
