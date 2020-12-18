"use strict"

const express = require("express")

// Constants
const PORT = 3000
const HOST = "0.0.0.0"

// API get request
var http = require("http")

// Client-side requests to API:
// (use https://example.com/api/*)

// Server-side requests to API:
// for docker-compose use "api" hostname (see docker-compose.yml)
// for ecs use service discovery hostname ending in .local (see api.tf)

let host =
  process.env.ENVIRONMENT === "dev"
    ? "api"
    : "api." + process.env.APP_DOMAIN_NAME + ".local"

let options = {
  host: host,
  path: "/api/",
}

// Hello world
const app = express()
app.get("/", (req, res) => {
  var req = http.get(options, function (api_res) {
    var bodyChunks = []
    api_res
      .on("data", function (chunk) {
        bodyChunks.push(chunk)
      })
      .on("end", function () {
        var body = Buffer.concat(bodyChunks)
        var jsonObj = JSON.parse(body)
        res.send({ from_express: "hello world", from_api: jsonObj })
      })
  })
})

app.listen(PORT, HOST)
