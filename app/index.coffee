dampexpert2 = require './lib/mvz' 3001, ->

  @extend 
    logger: require 'winston'
    repo: require './repository'
  
  @registerRoutes [
        'Home:index'
        'Products'
        'Offers'
        'Articles'
        'Contact'
        'Admin:admin'
      ]

  
module.exports = dampexpert2
