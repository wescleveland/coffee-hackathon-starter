passport = require("passport")
_ = require("underscore")
User = require("../models/User")

###
GET /login
Login page.
###
exports.getLogin = (req, res) ->
  return res.redirect("/")  if req.user
  res.render "account/login",
    title: "Login"

  return


###
POST /login
Sign in using email and password.
@param email
@param password
###
exports.postLogin = (req, res, next) ->
  req.assert("email", "Email is not valid").isEmail()
  req.assert("password", "Password cannot be blank").notEmpty()
  errors = req.validationErrors()
  if errors
    req.flash "errors", errors
    return res.redirect("/login")
  passport.authenticate("local", (err, user, info) ->
    return next(err)  if err
    unless user
      req.flash "errors",
        msg: info.message

      return res.redirect("/login")
    req.logIn user, (err) ->
      return next(err)  if err
      req.flash "success",
        msg: "Success! You are logged in."

      res.redirect "/"

    return
  ) req, res, next
  return


###
GET /logout
Log out.
###
exports.logout = (req, res) ->
  req.logout()
  res.redirect "/"
  return


###
GET /signup
Signup page.
###
exports.getSignup = (req, res) ->
  return res.redirect("/")  if req.user
  res.render "account/signup",
    title: "Create Account"

  return


###
POST /signup
Create a new local account.
@param email
@param password
###
exports.postSignup = (req, res, next) ->
  req.assert("email", "Email is not valid").isEmail()
  req.assert("password", "Password must be at least 4 characters long").len 4
  req.assert("confirmPassword", "Passwords do not match").equals req.body.password
  errors = req.validationErrors()
  if errors
    req.flash "errors", errors
    return res.redirect("/signup")
  user = new User(
    email: req.body.email
    password: req.body.password
  )
  user.save (err) ->
    if err
      if err.code is 11000
        req.flash "errors",
          msg: "User with that email already exists."

      return res.redirect("/signup")
    req.logIn user, (err) ->
      return next(err)  if err
      res.redirect "/"
      return

    return

  return


###
GET /account
Profile page.
###
exports.getAccount = (req, res) ->
  res.render "account/profile",
    title: "Account Management"

  return


###
POST /account/profile
Update profile information.
###
exports.postUpdateProfile = (req, res, next) ->
  User.findById req.user.id, (err, user) ->
    return next(err)  if err
    user.email = req.body.email or ""
    user.profile.name = req.body.name or ""
    user.profile.gender = req.body.gender or ""
    user.profile.location = req.body.location or ""
    user.profile.website = req.body.website or ""
    user.save (err) ->
      return next(err)  if err
      req.flash "success",
        msg: "Profile information updated."

      res.redirect "/account"
      return

    return

  return


###
POST /account/password
Update current password.
@param password
###
exports.postUpdatePassword = (req, res, next) ->
  req.assert("password", "Password must be at least 4 characters long").len 4
  req.assert("confirmPassword", "Passwords do not match").equals req.body.password
  errors = req.validationErrors()
  if errors
    req.flash "errors", errors
    return res.redirect("/account")
  User.findById req.user.id, (err, user) ->
    return next(err)  if err
    user.password = req.body.password
    user.save (err) ->
      return next(err)  if err
      req.flash "success",
        msg: "Password has been changed."

      res.redirect "/account"
      return

    return

  return


###
POST /account/delete
Delete user account.
@param id - User ObjectId
###
exports.postDeleteAccount = (req, res, next) ->
  User.remove
    _id: req.user.id
  , (err) ->
    return next(err)  if err
    req.logout()
    res.redirect "/"
    return

  return


###
GET /account/unlink/:provider
Unlink OAuth2 provider from the current user.
@param provider
@param id - User ObjectId
###
exports.getOauthUnlink = (req, res, next) ->
  provider = req.params.provider
  User.findById req.user.id, (err, user) ->
    return next(err)  if err
    user[provider] = `undefined`
    user.tokens = _.reject(user.tokens, (token) ->
      token.kind is provider
    )
    user.save (err) ->
      return next(err)  if err
      req.flash "info",
        msg: provider + " account has been unlinked."

      res.redirect "/account"
      return

    return

  return
