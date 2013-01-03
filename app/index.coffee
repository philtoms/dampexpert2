dampexpert2 = ->

  @logger = require 'winston'
  @repo = require './repository'
  @controllers = [
        'Home:index'
        'Products'
        'Offers'
        'Articles'
        'Contact'
        'Admin:admin'
      ]

module.exports = dampexpert2
