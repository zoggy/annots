console.log("start options-ui.js");

var data = { };
data.keys = [ ];
data.servers = [ ];

function serverDisplayState (server) {
  var id = '#server-'+server.id ;
  var sel = $(id + ' div.server-state');
  if (server.state.error) {
    $(id).addClass("alert alert-error");
    sel.text("Error: " + server.state.error);
  }
  else {
    $(id).addClass("alert alert-info");
    sel.text("Connected");
  }
}
function serverError(server, msg) {
  server.state = { error : msg } ;
}

function serverHandleChallenges(server, keys, data) {
  var json = $.parseJSON(data);
  console.log ("challenges: " + JSON.stringify(json));
}

function serverPostKeys(server,keys) {
  var json = keys.map(function (k) {
    switch (k.kind) {
    case "rsa":
        return { id: k.id, kind: k.kind, exponent: k.exponent, modulus: k.modulus };
    default:
        return { id: "", kind: ""};
    }
  });

  var q = $.ajax({
    url: server.url+'/auth/pubkeys',
    type: "POST",
    content: JSON.stringify(json),
    contentType: "application/json",
    accepts: "application/json",
    }) ;
  q.done(function (data) { serverHandleChallenges (server, keys, data.responseText); });
  q.fail(function (data) { serverError(server, "Could not connect to server ("+JSON.stringify(q)+")");} );
  q.always(function () { serverDisplayState(server); });
}

function getTokens(server,keys) {
  console.log("getTokens for "+server.name);
  serverPostKeys(server, keys);
}

function onKeyServersUpdate() {
  if (data.keys != [] && data.servers != []) {
    for (var i in data.servers) { getTokens(data.servers[i], data.keys); }
  }
}

function addServer(node,s) {
  console.log("Adding server "+s.name+": "+s.url);
  var div = $('<div id="server-'+s.id+'" class="server"/>') ;
  div.append('<div class="server-name">' + s.name + '</div>') ;
  div.append('<div class="server-url">' + s.url + '</div>') ;
  div.append('<div class="server-state">' + s.state + '</div>') ;
  node.append(div);
}

function setServers(servers) {
  console.log("received"+servers+"\n"+typeof servers);
  var div_servers = $("#servers") ;
  div_servers.empty();
  for (var i in servers) {
    var s = servers[i];
    s.id = i ;
    addServer(div_servers,s);
  }
  data.servers = servers ;
  onKeyServersUpdate();
}

function addKey(node,k) {
  console.log("Adding key "+k.id+": "+k.kind);
  var div = node.append('<div class="key">') ;
  div.append(k.id + ": " + k.kind);
}

function setKeys(keys) {
  console.log("received"+keys+"\n"+typeof keys);
  var div_keys = $("#keys") ;
  div_keys.empty();
  for (var i in keys) {
    var k = keys[i];
    addKey(div_keys,k);
  }
  data.keys = keys ;
  onKeyServersUpdate();
}


self.port.on("setServers", setServers);
self.port.on("setKeys", setKeys);
 