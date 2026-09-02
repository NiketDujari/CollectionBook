console.log("bridge.js loaded");

class FlutterBridge {

    constructor() {

        this.requestId = 0;

        this.pending = new Map();

    }

    send(method, payload = {}) {

        return new Promise((resolve, reject) => {

            const id = ++this.requestId;

            this.pending.set(id, {

                resolve,

                reject

            });

            StorageBridge.postMessage(

                JSON.stringify({

                    id,

                    method,

                    payload

                })

            );

        });

    }

    resolve(id, data) {

        const request = this.pending.get(id);

        if (!request) return;

        request.resolve(data);

        this.pending.delete(id);

    }

    reject(id, error) {

        const request = this.pending.get(id);

        if (!request) return;

        request.reject(error);

        this.pending.delete(id);

    }

}

window.flutterBridge = new FlutterBridge();



window.flutterResolve = function(id, data){

    window.flutterBridge.resolve(id, data);

};



window.flutterReject = function(id, error){

    window.flutterBridge.reject(id, error);

};



window.storage = {

    async get(key){

        const value = await flutterBridge.send(
            "get",
            {
                key
            }
        );

        if(value === null || value === undefined){

            return null;

        }

        return {

            value:value

        };

    },

    async set(key,value){

        return flutterBridge.send(
            "set",
            {
                key,
                value
            }
        );

    },

    async remove(key){

        return flutterBridge.send(
            "remove",
            {
                key
            }
        );

    },

    async delete(key){

        return flutterBridge.send(
            "remove",
            {
                key
            }
        );

    },

    async clear(){

        return flutterBridge.send(
            "clear"
        );

    }

};