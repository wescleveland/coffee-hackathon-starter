request = require("supertest")
app = require("../app")
describe "GET /", ->
  it "should return 200 OK", (done) ->
    request(app).get("/").expect 200, done
    return

  return

describe "GET /reset", ->
  it "should return 404", (done) ->
    request(app).get("/reset").expect 404, done
    return

  return


# this will fail
