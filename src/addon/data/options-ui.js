console.log("start options-ui.js");

function addServerDiv(server) {
  var div_servers = $("#servers") ;
  var div = $('<div id="server-' + server.id + '" class="server"/>') ;
  div_servers.append(div);
  return div;
}

function displayServer (server) {
  var id = "#server-" + server.id ;
  var div = $(id);
  if (div.length <= 0)
    { div = addServerDiv(server); }
  else
    { div.empty(); }

  div.removeClass("alert alert-info alert-error alert-success");
  var cl = (server.state_ok) ? ((server.state_writable) ? "alert-info" : "alert-success") : "alert-error" ;
  div.addClass("alert " + cl) ;

  var removeId = "remove-server-" + server.id ;
  var divname = $('<div/>',
    { class: "server-name",
    });
  var span = $('<span/>', {
    id: removeId,
    class: "ui-icon ui-icon-circle-minus",
    style: "display: inline-block",
    });
  span.click(function() { onRemoveServer(server); });
  divname.html(server.name + ' ');
  divname.append(span);
  div.append(divname);
  div.append('<div class="server-url">' + server.url + '</div>') ;
  div.append('<div class="server-state">' + server.state_info + '</div>') ;

}

function setServers(servers) {
  console.log("received" + servers + "\n" + typeof servers);
  var div_servers = $("#servers") ;
  div_servers.empty();
  for (var i in servers) {
    var s = servers[i];
    displayServer(s);
  }
}

function destroyServer(server) {
  $('#server-' + server.id).remove();
}

function addKeyDiv(key) {
  var div_keys = $("#keys") ;
  var div = $('<div id="key-' + key.id + '" class="key"/>') ;
  div_keys.append(div);
  return div;
}

function displayKey (key) {
  var id = "#key-" + key.id ;
  var div = $(id);
  if (div.length <= 0)
    { div = addKeyDiv(key); }
  else
    { div.empty(); }

  div.append('<div class="key-name">' + key.id + '</div>') ;
  div.append('<div class="key-kind">' + key.kind + '</div>') ;
}

function setKeys(keys) {
  console.log("received" + keys + "\n" + typeof keys);
  var div_keys = $("#keys") ;
  div_keys.empty();
  for (var i in keys) {
    var k = keys[i];
    displayKey(k);
  }
}

self.port.on ("setServers", function(data) {setServers(data);});
self.port.on ("setKeys", function(data) {setKeys(data);});
self.port.on ("updateServer", function(data) {displayServer(data);});
self.port.on ("removeServer", function(data) {destroyServer(data);});

$("#reconnect").button().click(function() { self.port.emit("reconnect");});
