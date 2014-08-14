var self = require("sdk/self");
var tabs = require("sdk/tabs");
var keys = require("keys");
var options = require("options");
var server = require("server");

tabs.open("file:///home/guesdon/devel/annots/draft/text.html");

tabs.on("ready", onPageLoad);

function onPageLoad(tab) {
  console.log("tab.url="+ tab.url);
  if (tab.url != options.option_tab_url) {
    var pm = require("sdk/page-mod").PageMod({
      include: tabs.activeTab.url,
      attachTo: ["existing", "top"],
      contentScriptFile: [
        self.data.url("jquery.js"),
        self.data.url("jquery-ui/jquery-ui.js"),
        self.data.url("moz-js.js"),
      ],
      contentStyleFile: self.data.url("jquery-ui/jquery-ui.css")
    });
  }
}

server.getTokensForServers();