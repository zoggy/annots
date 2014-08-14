console.log("start options-ui.js");

function serverAddDiv(server) {
  var div_servers = $("#servers") ;
  var div = $('<div id="server-' + server.id + '" class="server"/>') ;
  div_servers.append(div);
  return div;
}

function serverDisplay (server) {
  var id = "#server-" + server.id ;
  var div = $(id);
  if (div.length <= 0)
    { div = serverAddDiv(server); }
  else
    { div.empty(); }

  div.removeClass("alert alert-info alert-error alert-success");
  var cl = (server.state_ok) ? ((server.writable) ? "alert-info" : "alert-success") : "alert-error" ;
  div.addClass("alert " + cl) ;

  div.append('<div class="server-name">' + server.name + '</div>') ;
  div.append('<div class="server-url">' + server.url + '</div>') ;
  div.append('<div class="server-state">' + server.state_info + '</div>') ;
}

function setServers(servers) {
  console.log("received" + servers + "\n" + typeof servers);
  var div_servers = $("#servers") ;
  div_servers.empty();
  for (var i in servers) {
    var s = servers[i];
    s.id = i ;
    serverDisplay(s);
  }
}

self.port.on ("setServers", function(data) {setServers(data);});
//self.port.on ("setKeys", function(data) {setKeys(data);});
self.port.on ("updateServer", function(data) {ServerDisplay(data);});
