{ app } = require('../app')
_ = require('underscore')
_s = require('underscore.string')
countdown = require('countdown')
roller = require('../lib/roller')

app.get('/burningwheel', (req, res) ->
  res.render('burningwheel/index')
)
app.get('/burningwheel/:id', (req, res) ->
  res.render('burningwheel/index')
)
