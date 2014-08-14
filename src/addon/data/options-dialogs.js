
function addServer() {
  var name = $("#name").val();
  var url = $("#url").val();
  self.port.emit("addServer", { name: name, url: url });
  addServerDialog.dialog("close");
}

function removeServer(s) {
   self.port.emit("removeServer", s);
}

function confirmBox(title, msg, callback) {
  $('<div></div>').appendTo('body')
    .html('<div>'+msg+'</div>')
    .dialog({
        modal: true,
        title: title,
        zIndex: 10000,
        autoOpen: true,
        width: 'auto',
        resizable: false,
        buttons: {
            Yes: function () {
                // $(obj).removeAttr('onclick');
                // $(obj).parents('.Parent').remove();
                callback();
                $(this).dialog("close");
            },
            No: function () {
                $(this).dialog("close");
            }
        },
        close: function (event, ui) {
            $(this).remove();
        }
    });
}

function onRemoveServer(s) {
  confirmBox(
    "Remove server",
    'Remove server "' + s.name + '" ?',
    function () { removeServer(s); });
}

var addServerDialog =$("#add-server-form").dialog(
  {
    title: "Add annotation server",
    autoOpen: false,
    height: 400,
    width: 650,
    modal: true,
    buttons: {
     "Add server": addServer,
     Cancel: function() {
       addServerDialog.dialog( "close" );
       }
    },
    open: function() {
      $(this).load("options-dialogs.html #add-server-form");
    },
  }
);

$("#addServer").click(function(){ addServerDialog.dialog("open");});

