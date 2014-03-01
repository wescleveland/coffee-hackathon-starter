chai = require("chai")
should = chai.should()
User = require("../models/User")
describe "User attributes", ->
  it "email should be a string", ->
    user = new User(
      email: "janedoe@gmail.com"
      password: "password"
    )
    user.email.should.be.a "string"
    return

  it "password should be a string", ->
    user = new User(
      email: "janedoe@gmail.com"
      password: "password"
    )
    user.password.should.be.a "string"
    return

  it "should save a user", (done) ->
    user = new User(
      email: "janedoe@gmail.com"
      password: "password"
    )
    user.save()
    done()
    return

  it "should find our newly created user", (done) ->
    user = new User(
      email: "janedoe@gmail.com"
      password: "password"
    )
    user.save()
    User.findOne
      email: user.email
    , (err, user) ->
      should.exist user
      user.email.should.equal "janedoe@gmail.com"
      done()
      return

    return

  it "should not allow users with duplicate emails", (done) ->
    user = new User(
      email: "janedoe@gmail.com"
      password: "password"
    )
    user.save (err) ->
      err.code.should.equal 11000  if err
      done()
      return

    return

  return

