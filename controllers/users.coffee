{ app, config } = require('../app')
mongoose = require('mongoose')
{ Schema } = mongoose
mongoose_auth = require('mongoose-auth')

UserSchema = new Schema({})
hostname = 'http://localhost:3000'

{ session_secret, twitter_key, twitter_secret, facebook_id, facebook_secret, facebook_callback } = config

UserSchema.plugin(mongoose_auth,
  everymodule:
    everyauth:
      User: ->
        User
  facebook:
    everyauth:
      myHostname: hostname
      appId: facebook_id
      appSecret: facebook_secret
      redirectPath: '/'
  twitter:
    everyauth:
      myHostname: hostname
      consumerKey: twitter_key
      consumerSecret: twitter_secret
      redirectPath: '/'
  password:
    everyauth:
      getLoginPath: '/login'
      postLoginPath: '/login'
      loginView: 'login.jade'
      getRegisterPath: '/login'
      postRegisterPath: '/register'
      registerView: 'login.jade'
      loginSuccessRedirect: '/'
      registerSuccessRedirect: '/'
    loginWith: 'email'
)

User = mongoose.model('User', UserSchema)

app.use(mongoose_auth.middleware())
mongoose_auth.helpExpress(app)
