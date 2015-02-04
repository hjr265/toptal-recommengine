####
# This sample is published as part of the blog article at www.toptal.com/blog 
# Visit www.toptal.com/blog and subscribe to our newsletter to read great posts
####

_ = require 'underscore'
async = require 'async'
Bourne = require 'bourne'

module.exports = class Similars
	constructor: (@engine) ->
		@db = new Bourne './db-similars.json'

	byUser: (user, done) ->
		@db.findOne user: user, (err, {others}) =>
			if err?
				return done err

			done null, others

	update: (user, done) ->
		async.auto
			userLikes: (done) =>
				@engine.likes.itemsByUser user, done

			userDislikes: (done) =>
				@engine.dislikes.itemsByUser user, done

		, (err, {userLikes, userDislikes}) =>
			if err?
				return done err

			items = _.flatten([userLikes, userDislikes])
			async.map items, (item, done) =>
				async.map [
					@engine.likes
					@engine.dislikes

				], (rater, done) =>
					rater.usersByItem item, done

				, done

			, (err, others) =>
				if err?
					return done err

				others = _.without _.unique(_.flatten others), user
				@db.delete user: user, (err) =>
					if err?
						return done err

					async.map others, (other, done) =>
						async.auto
							otherLikes: (done) =>
								@engine.likes.itemsByUser other, done
							
							otherDislikes: (done) =>
								@engine.dislikes.itemsByUser other, done

						, (err, {otherLikes, otherDislikes}) =>
							if err?
								return done err

							done null,
								user: other
								similarity: (_.intersection(userLikes, otherLikes).length+_.intersection(userDislikes, otherDislikes).length-_.intersection(userLikes, otherDislikes).length-_.intersection(userDislikes, otherLikes).length) / _.union(userLikes, otherLikes, userDislikes, otherDislikes).length

					, (err, others) =>
						if err?
							return next err

						@db.insert
							user: user
							others: others
						, done
 
