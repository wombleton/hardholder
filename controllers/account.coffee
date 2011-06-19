
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
            res.redirect req.session.authenticated_redirect_url or '/'
            delete req.session.authenticated_redirect_url
    else
      res.redirect('/')          

  server.get '/auth/facebook', (req,res) ->
    unless req.query.denied
      req.authenticate ['facebook'], (error, authenticated) ->
        loadAccount req, (account) ->
          if req.query.oauth_token and req.query.oauth_verifier
            res.redirect req.session.authenticated_redirect_url or '/'
            delete req.session.authenticated_redirect_url
    else
      res.redirect('/')          
      