package haxe.ui.remoting.client;

import haxe.ui.remoting.Msg;
import haxe.ui.remoting.client.ClientSocket;
import haxe.ui.remoting.client.calls.Call;

#if neko
import neko.vm.Thread;
#elseif cpp
import cpp.vm.Thread;
#end

class Client {
    private var _socket:ClientSocket;

    public function new() {
        connect();
    }

    public function connect(host:String = "localhost", port:Int = 1234) {
        _socket = new ClientSocket();
        _socket.onMessage = onMessage;
        _socket.onError = onError;
        _socket.connect(host, port);
    }
    
    private function onMessage(msg:Msg) {
        var call:Call = Call.create(msg.id);
        if (msg.id == "client.connected") {
            return;
        }
        if (call == null) {
            trace("WARNING: message unrecognised, id=" + msg.id);
            return;
        }

        var details = call.execute(msg.details);
        if (details != null) {
            var response:Msg = {
                id: msg.id,
                details: details
            }

            _socket.sendMessage(response);
        }
    }
    
    private function onError(error:String) {
        trace(error);
        var t:Thread = Thread.create(retryThread);
        t.sendMessage(this);
    }
    
    private function retryThread() {
        var that:Client = Thread.readMessage(true);
        Sys.sleep(5);
        that.connect();
    }
}