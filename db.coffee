Mongoose = require('mongoose')

if process.env.server == 'TEST'
  db = Mongoose.connect('mongodb://localhost/test')
else
  db = Mongoose.connect('mongodb://localhost/db')
  
module.exports.db = db
