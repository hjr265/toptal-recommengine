####
# This sample is published as part of the blog article at www.toptal.com/blog
# Visit www.toptal.com/blog and subscribe to our newsletter to read great posts
####

_ = require 'underscore'
async = require 'async'
Bourne = require 'bourne'
express = require 'express'

movies = require './data/movies.json'

Engine = require './lib/engine'
e = new Engine

app = express()

app.set 'views', "#{__dirname}/views"
app.set 'view engine', 'jade'

app.route('/refresh')
.post(({query}, res, next) ->
	async.series [
		(done) =>
			e.similars.update query.user, done

		(done) =>
			e.suggestions.update query.user, done

	], (err) =>
		if err?
			return next err

		res.redirect "/?user=#{query.user}"
)

app.route('/like')
.post(({query}, res, next) ->
	if query.unset is 'yes'
		e.likes.remove query.user, query.movie, (err) =>
			if err?
				return next err

			res.redirect "/?user=#{query.user}"

	else
		e.dislikes.remove query.user, query.movie, (err) =>
			if err?
				return next err

			e.likes.add query.user, query.movie, (err) =>
				if err?
					return next err

				res.redirect "/?user=#{query.user}"
)

app.route('/dislike')
.post(({query}, res, next) ->
	if query.unset is 'yes'
		e.dislikes.remove query.user, query.movie, (err) =>
			if err?
				return next err

			res.redirect "/?user=#{query.user}"

	else
		e.likes.remove query.user, query.movie, (err) =>
			if err?
				return next err

			e.dislikes.add query.user, query.movie, (err) =>
				if err?
					return next err

				res.redirect "/?user=#{query.user}"
)

app.route('/')
.get(({query}, res, next) ->
	async.auto
		likes: (done) =>
			e.likes.itemsByUser query.user, done

		dislikes: (done) =>
			e.dislikes.itemsByUser query.user, done

		suggestions: (done) =>
			e.suggestions.forUser query.user, (err, suggestions) =>
				if err?
					return done err

				done null, _.map _.sortBy(suggestions, (suggestion) -> -suggestion.weight), (suggestion) =>
					_.findWhere movies, id: suggestion.item

	, (err, {likes, dislikes, suggestions}) =>
		if err?
			return next err

		res.render 'index',
			movies: movies
			user: query.user
			likes: likes
			dislikes: dislikes
			suggestions: suggestions[...4]
)

app.listen (port = 5000), (err) ->
	if err?
		throw err

	console.log "Listening on #{port}"
