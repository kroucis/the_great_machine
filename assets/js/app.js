// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative paths, for example:
import socket from "./socket"

import { Elm } from "../elm/src/Main.elm"

var app = Elm.Main.init({
  node: document.getElementById("elm-container-main")
})
app.channels = { }

app.ports.consoleLog.subscribe(function(msg) {
    console.log(msg)
})

app.ports.beginWork.subscribe(function() {
    app.ports.onMatchmaking.send(null)
    let matchChannel = socket.channel("match:0", {})
    matchChannel.onError(error => {
        console.log(error)
        matchChannel.leave()
        app.ports.onGameEvent.send({ event: "sys.disconnected", payload: null })
    })
    matchChannel.join()
    .receive("ok", resp => {
        matchChannel.push("join", {})
            .receive("ok", response => {
                console.log(response.data)
                app.ports.onMatchReady.send(response.data)
                matchChannel.on("sync.machine", response => {
                    console.log(response.data)
                    app.ports.onGameEvent.send({ event: "sync.machine", payload: response.data })
                })
                app.ports.sendGameEvent.subscribe(function(event) {
                    matchChannel.push(event.event, event.payload)
                        // .receive("ok", response => {
                        //     console.log(response)
                        //     app.ports.onGameEvent.send({ event: event.event, payload: response.data })
                        // })
                        .receive("error", error => {
                            console.log(error.data)
                        })
                })
            })

        // app.ports.onMatchReady.send({ match_id: 0, player_id: 0})
        // app.ports.sendGameEvent.subscribe(function(event) {
        //     matchChannel.push(event.event, event.payload)
        //         .receive("ok", response => {
        //             console.log(response)
        //             app.ports.onGameEvent.send({ event: event.event, payload: response.data })
        //         })
        // })
    })
    .receive("error", resp => {
        console.log("Failed to join Match 0")
    })
    // app.channels.match = matchChannel
})