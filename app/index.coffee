dampexpert2 = require './lib/mvz' 3001, (ready) ->

  @extend log: require ('winston').log
  @extend repo: require ('./repository')
  
  @registerRoutes [
        'Home:index'
        'Products'
        'Offers'
        'Articles'
        'Contact'
        'Admin:admin'
      ]

  ready()
  
module.exports = dampexpert2
