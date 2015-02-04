####
# This sample is published as part of the blog article at www.toptal.com/blog 
# Visit www.toptal.com/blog and subscribe to our newsletter to read great posts
####

_ = require 'underscore'
async = require 'async'
Bourne = require 'bourne'

module.exports = class Suggestions
	constructor: (@engine) ->
		@db = new Bourne './db-suggestions.json'

	forUser: (user, done) ->
		@db.findOne user: user, (err, {suggestions}={suggestion: []}) ->
			if err?
				return done err

			done null, suggestions

	update: (user, done) ->
		@engine.similars.byUser user, (err, others) =>
			if err?
				return done err

			async.auto 
				likes: (done) =>
					@engine.likes.itemsByUser user, done

				dislikes: (done) =>
					@engine.dislikes.itemsByUser user, done

				items: (done) =>
					async.map others, (other, done) =>
						async.map [
							@engine.likes
							@engine.dislikes

						], (rater, done) =>
							rater.itemsByUser other.user, done

						, done

					, done

			, (err, {likes, dislikes, items}) =>
				if err?
					return done err

				items = _.difference _.unique(_.flatten items), likes, dislikes
				@db.delete user: user, (err) =>
					if err?
						return done err

					async.map items, (item, done) =>
						async.auto
							likers: (done) =>
								@engine.likes.usersByItem item, done

							dislikers: (done) =>
								@engine.dislikes.usersByItem item, done

						, (err, {likers, dislikers}) =>
							if err?
								return done err

							numerator = 0
							for other in _.without _.flatten([likers, dislikers]), user
								other = _.findWhere(others, user: other)
								if other?
									numerator += other.similarity

							done null,
								item: item
								weight: numerator / _.union(likers, dislikers).length

					, (err, suggestions) =>
						if err?
							return done err

						@db.insert
							user: user
							suggestions: suggestions
						, done
