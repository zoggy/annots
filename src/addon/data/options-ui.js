console.log("start options-ui.js");


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

}

self.port.on("setServers", setServers);
 