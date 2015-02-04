####
# This sample is published as part of the blog article at www.toptal.com/blog 
# Visit www.toptal.com/blog and subscribe to our newsletter to read great posts
####

_ = require 'underscore'
async = require 'async'
Bourne = require 'bourne'

module.exports = class Rater
	constructor: (@engine, @kind) ->
		@db = new Bourne "./db-#{@kind}.json"

	add: (user, item, done) ->
		@db.find user: user, item: item, (err, res) =>
			if err?
				return done err

			if res.length > 0
				return done()

			@db.insert user: user, item: item, (err) =>
				if err?
					return done err

				async.series [
					(done) =>
						@engine.similars.update user, done
					(done) =>
						@engine.suggestions.update user, done
				], done

	remove: (user, item, done) ->
		@db.delete user: user, item: item, (err) =>
			if err?
				return done err

			async.series [
				(done) =>
					@engine.similars.update user, done
				(done) =>
					@engine.suggestions.update user, done
			], done

	itemsByUser: (user, done) ->
		@db.find user: user, (err, ratings) =>
			if err?
				return done err

			done null, _.pluck ratings, 'item'

	usersByItem: (item, done) ->
		@db.find item: item, (err, ratings) =>
			if err?
				return done err

			done null, _.pluck ratings, 'user'
