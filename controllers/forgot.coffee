async = require("async")
crypto = require("crypto")
nodemailer = require("nodemailer")
User = require("../models/User")
secrets = require("../config/secrets")

###
GET /forgot
Forgot Password page.
###
exports.getForgot = (req, res) ->
  return res.redirect("/")  if req.isAuthenticated()
  res.render "account/forgot",
    title: "Forgot Password"

  return


###
POST /forgot
Create a random token, then the send user an email with a reset link.
@param email
###
exports.postForgot = (req, res, next) ->
  req.assert("email", "Please enter a valid email address.").isEmail()
  errors = req.validationErrors()
  if errors
    req.flash "errors", errors
    return res.redirect("/forgot")
  async.waterfall [
    (done) ->
      crypto.randomBytes 20, (err, buf) ->
        token = buf.toString("hex")
        done err, token
        return

    (token, done) ->
      User.findOne
        email: req.body.email.toLowerCase()
      , (err, user) ->
        unless user
          req.flash "errors",
            msg: "No account with that email address exists."

          return res.redirect("/forgot")
        user.resetPasswordToken = token
        user.resetPasswordExpires = Date.now() + 3600000 # 1 hour
        user.save (err) ->
          done err, token, user
          return

        return

    (token, user, done) ->
      smtpTransport = nodemailer.createTransport("SMTP",
        service: "SendGrid"
        auth:
          user: secrets.sendgrid.user
          pass: secrets.sendgrid.password
      )
      mailOptions =
        to: user.profile.name + " <" + user.email + ">"
        from: "hackathon@starter.com"
        subject: "Hackathon Starter Password Reset"
        text: "You are receiving this because you (or someone else) have requested the reset of the password for your account.\n\n" + "Please click on the following link, or paste this into your browser to complete the process:\n\n" + "http://" + req.headers.host + "/reset/" + token + "\n\n" + "If you did not request this, please ignore this email and your password will remain unchanged.\n"

      smtpTransport.sendMail mailOptions, (err) ->
        req.flash "info",
          msg: "An e-mail has been sent to " + user.email + " with further instructions."

        done err, "done"
        return

  ], (err) ->
    return next(err)  if err
    res.redirect "/forgot"
    return

  return
