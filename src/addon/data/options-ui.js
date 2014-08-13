console.log("start options-ui.js");

var data = { };
data.keys = [ ];
data.servers = [ ];

function getTokens(server,keys) {

}

function onKeyServersUpdate() {
  if (data.keys != [] && data.servers != []) {
    for (var s in data.servers) { getTokens(s,data.keys); }
  }
}

function addServer(node,s) {
  console.log("Adding server "+s.name+": "+s.url);
  var div = node.append('<div class="server">') ;
  div.append(s.name + ": " + s.url);
}

function setServers(servers) {
  console.log("received"+servers+"\n"+typeof servers);
  var div_servers = $("#servers") ;
  div_servers.empty();
  for (var i in servers) {
    var s = servers[i];
    addServer(div_servers,s);
  }
  data.servers = servers ;
  onKeyServersUpdate();
}

function addKey(node,k) {
  console.log("Adding key "+k.name+": "+k.type);
  var div = node.append('<div class="key">') ;
  div.append(k.name + ": " + k.type);
}

function setKeys(keys) {
  console.log("received"+keys+"\n"+typeof keys);
  var div_keys = $("#keys") ;
  div_keys.empty();
  for (var i in keys) {
    var s = keys[i];
    addKey(div_keys,s);
  }
  data.keys = keys ;
  onKeyServersUpdate();
}


self.port.on("setServers", setServers);
self.port.on("setKeys", setKeys);
 