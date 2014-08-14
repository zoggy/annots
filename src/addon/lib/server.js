var self = require("sdk/self");
var keys = require("keys");
var options = require("options");
var Request = require("sdk/request").Request;

function displayServer(server) {
  options.send_to_tab("updateServer", server);
}

function serverError(server, msg) {
  server.state_ok = false;
  server.state_info = msg;
  server.state_writable = false ;
}
function serverOk(server, msg) {
  server.state_ok = true ;
  server.state_info = msg ;
}

function responseOk (response) {
  return (response.status >= 200 && response.status < 300);
}
function serverOnPostChallengesComplete(server, response) {
  console.log("/auth/challenges response: "+response.text);
  if (responseOk(response)) {
    var json = response.json;
    server.writable = (json.writable == null) ? false : json.writable ;
    var msg = "Connected "+(server.writable ? "and writable " : "") + " with " + json.number_of_rights + " rights" ;
    serverOk(server, msg);
  }
  else
    serverError(server, "Error " + response.status + ": " + response.text);
}

function serverPostChallenges(server, json) {
  var content = JSON.stringify(json) ;
  console.log(content);
  var url = server.url + '/auth/challenges';
  var req = Request({
    url: url,
    contentType: "application/json",
    content: content,
    headers: {
      accept: "application/json",
    },
    onComplete: function (response) { serverOnPostChallengesComplete(server, response);},
    }) ;
  req.post();
}

function json_of_key (k) {
  switch (k.kind) {
  case "rsa":
      return { id: k.id, kind: k.kind, exponent: k.exponent, modulus: k.modulus };
  default:
      return { id: "", kind: ""};
  }
}

function key_by_id(keys,id) {
  for (var i in keys) {
    if (keys[i].id == id) return keys[i];
  }
  return null;
}

function create_challenge_response (k, chal) {
  /* FIXME: use key to decrypt challenge data */
  { challenge_id : chal.challenge_id; data : "foo" }
}

function serverOnPubkeysComplete(server, keys, response) {
  console.log("reponse: "+response.text);
  if (responseOk(response)) {
    var json = JSON.parse(response.text);
    /* FIXME: check that Array.prototype.reduce is available ? (it is in Firefox) */
    var challenges = json.reduce
      (function (acc, v) {
         var k = key_by_id(keys, v.id);
         if (k != null) {
           var r = create_challenge_response (k, v) ;
           return [ r ].concat(acc) ;
         }
         else
           return acc;
      }, [ ]);
      serverPostChallenges(server, challenges);
  }
  else
     serverError(server, "Error " + response.status + ": "+ response.text);
}

function serverPostKeys(server,keys) {
  var json = keys.map(json_of_key);
  var content = JSON.stringify(json) ;
  console.log(content);
  var url = server.url+'/auth/pubkeys';
  var req = Request({
    url: url,
    contentType: "application/json",
    content: content,
    headers: {
      accept: "application/json",
    },
    onComplete: function (response) {
      serverOnPubkeysComplete(server,keys,response);
    }
    }) ;
  req.post();
}

function getTokens(server,keys) {
  console.log("getTokens for "+server.name);
  serverPostKeys(server, keys);
}

function getTokensForServers() {
  options.store.servers.forEach(function(s) { getTokens(s,options.store.keys);});
}

exports.getTokensForServers = getTokensForServers;
