Mongoose = require('mongoose')

if process.env.server == 'TEST'
  db = Mongoose.connect('mongodb://localhost/test')
else
  db = Mongoose.connect(process.env.MONGOLAB_URI)

module.exports.db = db
