####
# This sample is published as part of the blog article at www.toptal.com/blog 
# Visit www.toptal.com/blog and subscribe to our newsletter to read great posts
####

async = require 'async'
Rater = require './rater'
Similars = require './similars'
Suggestions = require './suggestions'

module.exports = class Engine
	constructor: ->
		@likes = new Rater @, 'likes'
		@dislikes = new Rater @, 'dislikes'
		@similars = new Similars @
		@suggestions = new Suggestions @

