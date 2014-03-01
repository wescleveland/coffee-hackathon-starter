secrets = require("../config/secrets")
User = require("../models/User")
querystring = require("querystring")
validator = require("validator")
async = require("async")
cheerio = require("cheerio")
request = require("request")
_ = require("underscore")
graph = require("fbgraph")
LastFmNode = require("lastfm").LastFmNode
tumblr = require("tumblr.js")
foursquare = require("node-foursquare")(secrets: secrets.foursquare)
Github = require("github-api")
Twit = require("twit")
paypal = require("paypal-rest-sdk")
twilio = require("twilio")(secrets.twilio.sid, secrets.twilio.token)
Linkedin = require("node-linkedin")(secrets.linkedin.clientID, secrets.linkedin.clientSecret, secrets.linkedin.callbackURL)
clockwork = require("clockwork")(key: secrets.clockwork.apiKey)

###
GET /api
List of API examples.
###
exports.getApi = (req, res) ->
  res.render "api/index",
    title: "API Browser"

  return


###
GET /api/foursquare
Foursquare API example.
###
exports.getFoursquare = (req, res, next) ->
  token = _.findWhere(req.user.tokens,
    kind: "foursquare"
  )
  async.parallel
    trendingVenues: (callback) ->
      foursquare.Venues.getTrending "40.7222756", "-74.0022724",
        limit: 50
      , token.accessToken, (err, results) ->
        callback err, results
        return

      return

    venueDetail: (callback) ->
      foursquare.Venues.getVenue "49da74aef964a5208b5e1fe3", token.accessToken, (err, results) ->
        callback err, results
        return

      return

    userCheckins: (callback) ->
      foursquare.Users.getCheckins "self", null, token.accessToken, (err, results) ->
        callback err, results
        return

      return
  , (err, results) ->
    return next(err)  if err
    res.render "api/foursquare",
      title: "Foursquare API"
      trendingVenues: results.trendingVenues
      venueDetail: results.venueDetail
      userCheckins: results.userCheckins

    return

  return


###
GET /api/tumblr
Tumblr API example.
###
exports.getTumblr = (req, res) ->
  token = _.findWhere(req.user.tokens,
    kind: "tumblr"
  )
  client = tumblr.createClient(
    consumer_key: secrets.tumblr.consumerKey
    consumer_secret: secrets.tumblr.consumerSecret
    token: token.accessToken
    token_secret: token.tokenSecret
  )
  client.posts "goddess-of-imaginary-light.tumblr.com",
    type: "photo"
  , (err, data) ->
    res.render "api/tumblr",
      title: "Tumblr API"
      blog: data.blog
      photoset: data.posts[0].photos

    return

  return


###
GET /api/facebook
Facebook API example.
###
exports.getFacebook = (req, res, next) ->
  token = _.findWhere(req.user.tokens,
    kind: "facebook"
  )
  graph.setAccessToken token.accessToken
  async.parallel
    getMe: (done) ->
      graph.get req.user.facebook, (err, me) ->
        done err, me
        return

      return

    getMyFriends: (done) ->
      graph.get req.user.facebook + "/friends", (err, friends) ->
        done err, friends.data
        return

      return
  , (err, results) ->
    return next(err)  if err
    res.render "api/facebook",
      title: "Facebook API"
      me: results.getMe
      friends: results.getMyFriends

    return

  return


###
GET /api/scraping
Web scraping example using Cheerio library.
###
exports.getScraping = (req, res, next) ->
  request.get "https://news.ycombinator.com/", (err, request, body) ->
    return next(err)  if err
    $ = cheerio.load(body)
    links = []
    $(".title a[href^='http'], a[href^='https']").each ->
      links.push $(this)
      return

    res.render "api/scraping",
      title: "Web Scraping"
      links: links

    return

  return


###
GET /api/github
GitHub API Example.
###
exports.getGithub = (req, res) ->
  token = _.findWhere(req.user.tokens,
    kind: "github"
  )
  github = new Github(token: token.accessToken)
  repo = github.getRepo("sahat", "requirejs-library")
  repo.show (err, repo) ->
    res.render "api/github",
      title: "GitHub API"
      repo: repo

    return

  return


###
GET /api/aviary
Aviary image processing example.
###
exports.getAviary = (req, res) ->
  res.render "api/aviary",
    title: "Aviary API"

  return


###
GET /api/nyt
New York Times API example.
###
exports.getNewYorkTimes = (req, res, next) ->
  query = querystring.stringify(
    "api-key": secrets.nyt.key
    "list-name": "young-adult"
  )
  url = "http://api.nytimes.com/svc/books/v2/lists?" + query
  request.get url, (error, request, body) ->
    return next(Error("Missing or Invalid New York Times API Key"))  if request.statusCode is 403
    bestsellers = JSON.parse(body)
    res.render "api/nyt",
      title: "New York Times API"
      books: bestsellers.results

    return

  return


###
GET /api/lastfm
Last.fm API example.
###
exports.getLastfm = (req, res, next) ->
  lastfm = new LastFmNode(secrets.lastfm)
  async.parallel
    artistInfo: (done) ->
      lastfm.request "artist.getInfo",
        artist: "Epica"
        handlers:
          success: (data) ->
            done null, data
            return

          error: (err) ->
            done err
            return

      return

    artistTopAlbums: (done) ->
      lastfm.request "artist.getTopAlbums",
        artist: "Epica"
        handlers:
          success: (data) ->
            albums = []
            _.each data.topalbums.album, (album) ->
              albums.push album.image.slice(-1)[0]["#text"]
              return

            done null, albums.slice(0, 4)
            return

          error: (err) ->
            done err
            return

      return
  , (err, results) ->
    return next(err.message)  if err
    artist =
      name: results.artistInfo.artist.name
      image: results.artistInfo.artist.image.slice(-1)[0]["#text"]
      tags: results.artistInfo.artist.tags.tag
      bio: results.artistInfo.artist.bio.summary
      stats: results.artistInfo.artist.stats
      similar: results.artistInfo.artist.similar.artist
      topAlbums: results.artistTopAlbums

    res.render "api/lastfm",
      title: "Last.fm API"
      artist: artist

    return

  return


###
GET /api/twitter
Twiter API example.
###
exports.getTwitter = (req, res, next) ->
  token = _.findWhere(req.user.tokens,
    kind: "twitter"
  )
  T = new Twit(
    consumer_key: secrets.twitter.consumerKey
    consumer_secret: secrets.twitter.consumerSecret
    access_token: token.accessToken
    access_token_secret: token.tokenSecret
  )
  T.get "search/tweets",
    q: "hackathon since:2013-01-01"
    geocode: "40.71448,-74.00598,5mi"
    count: 50
  , (err, reply) ->
    return next(err)  if err
    res.render "api/twitter",
      title: "Twitter API"
      tweets: reply.statuses

    return

  return


###
GET /api/paypal
PayPal SDK example.
###
exports.getPayPal = (req, res, next) ->
  paypal.configure secrets.paypal
  payment_details =
    intent: "sale"
    payer:
      payment_method: "paypal"

    redirect_urls:
      return_url: secrets.paypal.returnUrl
      cancel_url: secrets.paypal.cancelUrl

    transactions: [
      description: "Node.js Boilerplate"
      amount:
        currency: "USD"
        total: "2.99"
    ]

  paypal.payment.create payment_details, (err, payment) ->
    return next(err)  if err
    req.session.payment_id = payment.id
    links = payment.links
    i = 0

    while i < links.length
      if links[i].rel is "approval_url"
        res.render "api/paypal",
          approval_url: links[i].href

      i++
    return

  return


###
GET /api/paypal/success
PayPal SDK example.
###
exports.getPayPalSuccess = (req, res, next) ->
  payment_id = req.session.payment_id
  payment_details = payer_id: req.query.PayerID
  paypal.payment.execute payment_id, payment_details, (error, payment) ->
    if error
      res.render "api/paypal",
        result: true
        success: false

    else
      res.render "api/paypal",
        result: true
        success: true

    return

  return


###
GET /api/paypal/cancel
PayPal SDK example.
###
exports.getPayPalCancel = (req, res, next) ->
  req.session.payment_id = null
  res.render "api/paypal",
    result: true
    canceled: true

  return


###
GET /api/steam
Steam API example.
###
exports.getSteam = (req, res, next) ->
  steamId = "76561197982488301"
  query =
    l: "english"
    steamid: steamId
    key: secrets.steam.apiKey

  async.parallel
    playerAchievements: (done) ->
      query.appid = "49520"
      qs = querystring.stringify(query)
      request.get
        url: "http://api.steampowered.com/ISteamUserStats/GetPlayerAchievements/v0001/?" + qs
        json: true
      , (error, request, body) ->
        return done(new Error("Missing or Invalid Steam API Key"))  if request.statusCode is 401
        done error, body
        return

      return

    playerSummaries: (done) ->
      query.steamids = steamId
      qs = querystring.stringify(query)
      request.get
        url: "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?" + qs
        json: true
      , (error, request, body) ->
        return done(new Error("Missing or Invalid Steam API Key"))  if request.statusCode is 401
        done error, body
        return

      return

    ownedGames: (done) ->
      query.include_appinfo = 1
      query.include_played_free_games = 1
      qs = querystring.stringify(query)
      request.get
        url: "http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?" + qs
        json: true
      , (error, request, body) ->
        return done(new Error("Missing or Invalid Steam API Key"))  if request.statusCode is 401
        done error, body
        return

      return
  , (err, results) ->
    return next(err)  if err
    res.render "api/steam",
      title: "Steam Web API"
      ownedGames: results.ownedGames.response.games
      playerAchievemments: results.playerAchievements.playerstats
      playerSummary: results.playerSummaries.response.players[0]

    return

  return


###
GET /api/twilio
Twilio API example.
###
exports.getTwilio = (req, res, next) ->
  res.render "api/twilio",
    title: "Twilio API"

  return


###
POST /api/twilio
Twilio API example.
@param telephone
###
exports.postTwilio = (req, res, next) ->
  message =
    to: req.body.telephone
    from: "+13472235148"
    body: "Hello from the Hackathon Starter"

  twilio.sendMessage message, (err, responseData) ->
    return next(err.message)  if err
    req.flash "success",
      msg: "Text sent to " + responseData.to + "."

    res.redirect "/api/twilio"
    return

  return


###
GET /api/clockwork
Clockwork SMS API example.
###
exports.getClockwork = (req, res) ->
  res.render "api/clockwork",
    title: "Clockwork SMS API"

  return


###
POST /api/clockwork
Clockwork SMS API example.
@param telephone
###
exports.postClockwork = (req, res, next) ->
  message =
    To: req.body.telephone
    From: "Hackathon"
    Content: "Hello from the Hackathon Starter"

  clockwork.sendSms message, (err, responseData) ->
    return next(err.errDesc)  if err
    req.flash "success",
      msg: "Text sent to " + responseData.responses[0].to

    res.redirect "/api/clockwork"
    return

  return


###
GET /api/venmo
Venmo API example.
###
exports.getVenmo = (req, res, next) ->
  token = _.findWhere(req.user.tokens,
    kind: "venmo"
  )
  query = querystring.stringify(access_token: token.accessToken)
  async.parallel
    getProfile: (done) ->
      request.get
        url: "https://api.venmo.com/v1/me?" + query
        json: true
      , (err, request, body) ->
        done err, body
        return

      return

    getRecentPayments: (done) ->
      request.get
        url: "https://api.venmo.com/v1/payments?" + query
        json: true
      , (err, request, body) ->
        done err, body
        return

      return
  , (err, results) ->
    return next(err)  if err
    res.render "api/venmo",
      title: "Venmo API"
      profile: results.getProfile.data
      recentPayments: results.getRecentPayments.data

    return

  return


###
POST /api/venmo
@param user
@param note
@param amount
Send money.
###
exports.postVenmo = (req, res, next) ->
  req.assert("user", "Phone, Email or Venmo User ID cannot be blank").notEmpty()
  req.assert("note", "Please enter a message to accompany the payment").notEmpty()
  req.assert("amount", "The amount you want to pay cannot be blank").notEmpty()
  errors = req.validationErrors()
  if errors
    req.flash "errors", errors
    return res.redirect("/api/venmo")
  token = _.findWhere(req.user.tokens,
    kind: "venmo"
  )
  formData =
    access_token: token.accessToken
    note: req.body.note
    amount: req.body.amount

  if validator.isEmail(req.body.user)
    formData.email = req.body.user
  else if validator.isNumeric(req.body.user) and validator.isLength(req.body.user, 10, 11)
    formData.phone = req.body.user
  else
    formData.user_id = req.body.user
  request.post "https://api.venmo.com/v1/payments",
    form: formData
  , (err, request, body) ->
    return next(err)  if err
    if request.statusCode isnt 200
      req.flash "errors",
        msg: JSON.parse(body).error.message

      return res.redirect("/api/venmo")
    req.flash "success",
      msg: "Venmo money transfer complete"

    res.redirect "/api/venmo"
    return

  return


###
GET /api/linkedin
LinkedIn API example.
###
exports.getLinkedin = (req, res, next) ->
  token = _.findWhere(req.user.tokens,
    kind: "linkedin"
  )
  linkedin = Linkedin.init(token.accessToken)
  linkedin.people.me (err, $in) ->
    return next(err)  if err
    res.render "api/linkedin",
      title: "LinkedIn API"
      profile: $in

    return

  return
