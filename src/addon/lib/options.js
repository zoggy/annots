var self = require("sdk/self");
var tabs = require("sdk/tabs");
var ss = require("sdk/simple-storage");
var pageMod = require("sdk/page-mod");
var store = ss.storage;

store.servers = [
  { url : 'http://localhost:8082',
    name : "local"
  }
  ];

store.keys = [
  { id: "mainkey",
    kind : "rsa",
    exponent : "65567",
    modulus : "929123091209124"
  }
]


var option_tab = null ;
const option_tab_url = self.data.url("options-main.html");
exports.option_tab_url = option_tab_url ;

function close_option_tab(tab) {
  option_tab = null ;
}

function on_option_tab_open(tab) {
  option_tab = tab;
  var pm = pageMod.PageMod({
    include: option_tab_url,
    attachTo: ["existing", "top"],
    onAttach: function(worker) {
      console.log("sending message")
      worker.port.emit("setServers", store.servers);
      worker.port.emit("setKeys", store.keys);
      /*worker.port.on("gotElement", function(elementContent) {
      console.log(elementContent);
    });*/
    },
    contentScriptWhen: "ready",
    contentScriptFile: [
      self.data.url('jquery.js'),
      self.data.url('jquery-ui/jquery-ui.js'),
      self.data.url('options-ui.js'),
    ],
    contentStyleFile: [
      self.data.url('jquery-ui/jquery-ui.css'),
      self.data.url('style.css'),
    ],
  });

}

function create_option_tab () {
  tabs.open({
    url: option_tab_url,
    onOpen: on_option_tab_open,
    onClose: function(tab) { close_option_tab(tab); },
    });
}

function activate_option_tab () {
  console.log (option_tab);
  if (option_tab != null) {
    option_tab.activate();
  }
  else {
    create_option_tab();
  }
}
var { ActionButton } = require("sdk/ui/button/action");

var button = ActionButton({
    id: "btn-options",
    label: "Annots options",
    icon: {
      "16": "./annots-16.png",
      "32": "./annots-32.png"
    },
    onClick: function(state) {
      activate_option_tab () ;
    }
  });