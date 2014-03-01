async = require("async")
nodemailer = require("nodemailer")
User = require("../models/User")
secrets = require("../config/secrets")

###
GET /reset/:token
Reset Password page.
###
exports.getReset = (req, res) ->
  return res.redirect("/")  if req.isAuthenticated()
  User.findOne(resetPasswordToken: req.params.token).where("resetPasswordExpires").gt(Date.now()).exec (err, user) ->
    unless user
      req.flash "errors",
        msg: "Password reset token is invalid or has expired."

      return res.redirect("/forgot")
    res.render "account/reset",
      title: "Password Reset"

    return

  return


###
POST /reset/:token
Process the reset password request.
###
exports.postReset = (req, res, next) ->
  req.assert("password", "Password must be at least 4 characters long.").len 4
  req.assert("confirm", "Passwords must match.").equals req.body.password
  errors = req.validationErrors()
  if errors
    req.flash "errors", errors
    return res.redirect("back")
  async.waterfall [
    (done) ->
      User.findOne(resetPasswordToken: req.params.token).where("resetPasswordExpires").gt(Date.now()).exec (err, user) ->
        unless user
          req.flash "errors",
            msg: "Password reset token is invalid or has expired."

          return res.redirect("back")
        user.password = req.body.password
        user.resetPasswordToken = `undefined`
        user.resetPasswordExpires = `undefined`
        user.save (err) ->
          return next(err)  if err
          req.logIn user, (err) ->
            done err, user
            return

          return

        return

    (user, done) ->
      smtpTransport = nodemailer.createTransport("SMTP",
        service: "SendGrid"
        auth:
          user: secrets.sendgrid.user
          pass: secrets.sendgrid.password
      )
      mailOptions =
        to: user.profile.name + " <" + user.email + ">"
        from: "hackathon@starter.com"
        subject: "Your Hackathon Starter password has been changed"
        text: "Hello,\n\n" + "This is a confirmation that the password for your account " + user.email + " has just been changed.\n"

      smtpTransport.sendMail mailOptions, (err) ->
        req.flash "success",
          msg: "Success! Your password has been changed."

        done err
        return

  ], (err) ->
    return next(err)  if err
    res.redirect "/"
    return

  return
