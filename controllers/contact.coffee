secrets = require("../config/secrets")
nodemailer = require("nodemailer")
smtpTransport = nodemailer.createTransport("SMTP",
  
  #  service: 'Mailgun',
  #  auth: {
  #    user: secrets.mailgun.login,
  #    pass: secrets.mailgun.password
  #  }
  service: "SendGrid"
  auth:
    user: secrets.sendgrid.user
    pass: secrets.sendgrid.password
)

###
GET /contact
Contact form page.
###
exports.getContact = (req, res) ->
  res.render "contact",
    title: "Contact"

  return


###
POST /contact
Send a contact form via Nodemailer.
@param email
@param name
@param message
###
exports.postContact = (req, res) ->
  req.assert("name", "Name cannot be blank").notEmpty()
  req.assert("email", "Email is not valid").isEmail()
  req.assert("message", "Message cannot be blank").notEmpty()
  errors = req.validationErrors()
  if errors
    req.flash "errors", errors
    return res.redirect("/contact")
  from = req.body.email
  name = req.body.name
  body = req.body.message
  to = "your@email.com"
  subject = "API Example | Contact Form"
  mailOptions =
    to: to
    from: from
    subject: subject
    text: body + "\n\n" + name

  smtpTransport.sendMail mailOptions, (err) ->
    if err
      req.flash "errors",
        msg: err.message

      return res.redirect("/contact")
    req.flash "success",
      msg: "Email has been sent successfully!"

    res.redirect "/contact"
    return

  return
