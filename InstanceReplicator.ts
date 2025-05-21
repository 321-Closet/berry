//@author: 321 Closet
/*
    @description: Replicator is a library that allows developers to create custom instance replication logic.
    The concept of this library is not to have entire pools of information sent to the client for replication, but rather
    the ability to have unique instances and specify whether to be rendered or not, with the freedom to write 3 32 bit signed integers
    as useable data to the client
*/
const HttpService = game.GetService('HttpService');

// Calculates the fraction frequency at which data is sent through the network
export function CalculateFrequency(f: number) {
    const upperLimit = 12;
    assert(f > upperLimit, "Upper frequency limit is 12hz, please enter a lower value");

    return 1/f;
}

// Creates a new replication buffer object from the given size in bytes
export function CreateBuffer(bufferSize: number) {
    return buffer.create(bufferSize);
}

/*
    Called after create buffer, sets up the buffer for n instances found on the server that require replication
    Should be called after some instances are serialized and server primitives have been created, otherwise will return
    null buffer, this function can be overloaded as long as you make your own set buffer that returns the object for the network

    serializedIds: 36 bytes
    allowed: 3 32 bit signed integers or floats per instance
*/
export function SetBuffer(bufferObject: buffer, camera: Camera) {
    assert(bufferObject, "Cannot set buffer with argument #1 missing or null");
    const serverPrimitives: Instance[] = camera.GetChildren();
    let newBufferObject = bufferObject
    let offset = 0;

    for (const primitive of serverPrimitives) {
        let serializedId = primitive.GetTags()[0];
        buffer.writestring(newBufferObject, offset, serializedId);
        offset += 41; // bytes leaving spot for 3 signed 32 bit integers or floats to be written
    }

    return newBufferObject;
}

// Call with argument #1 being a formatted buffer object with SetBuffer
export function WriteIntegerToBuffer(setBufferObject: buffer, i32: number, serializedId: string) {
    const upperLimit = 2147483647;
    const lowerLimit = -2147483648;
    let offset = 0;

    let integer = math.clamp(i32, lowerLimit, upperLimit);

    let co = coroutine.wrap(function(){
        while (true) {
            let id = buffer.readstring(setBufferObject, offset, 36);
            if (id != serializedId) {
                offset += 41;
            } else if (id === serializedId) {
                let currentNumber = buffer.readi32(setBufferObject, offset);
                if (currentNumber > 0) {
                    offset += 4;
                    buffer.writei32(setBufferObject, offset, integer);
                } else {
                    buffer.writei32(setBufferObject, offset, integer);
                }  
                break
            }
        }

        return true
    })

    return co()
}

export function WriteFloatToBuffer(setBufferObject: buffer, f32: number, serializedId: string) {
    const upperLimit = 2147483647;
    const lowerLimit = -2147483648;
    let offset = 0;

    let float =  math.clamp(f32, lowerLimit, upperLimit);

    let co = coroutine.wrap(function(){
        while (true) {
            let id = buffer.readstring(setBufferObject, offset, 36);
            if (id != serializedId) {
                offset += 41;
            } else if (id === serializedId) {
                let currentNumber = buffer.readf32(setBufferObject, offset)
                if (currentNumber > 0) {
                    offset += 4;
                    buffer.writef32(setBufferObject, offset, float);
                } else {
                    buffer.writef32(setBufferObject, offset, float);
                }
                break
            }
        }

        return true
    })

    return co()
}

/* Takes in a clone instance of a original instance, and creates 2 tags for it, one is the tag applied
    on the instance that the client can use to find the specified clone, while the other tells the client where to look,
    if the render tag is in the buffer id then it means that the client should look in a given folder to find the clone
    and render it otherwise look in the workspace and do something that the client interpreter specifies to do.
    This assumes that you clone instances that require this replication, and call the MakePrimitive on the server to be an abstract
    representation of the cloned instance
*/ 
export function SerializeInstance(instance: Instance, includeRenderTag: boolean) {
    const instanceId = HttpService.GenerateGUID(false);

    if (includeRenderTag) {
        let instanceIdWithTag = instanceId+'r';
        instance.AddTag(instanceId);
        return instanceIdWithTag;
    } else {
        instance.AddTag(instanceId);
        return instanceId;
    }
}

/* Makes a primitive geometric object to corespond to the given instance for server->client replication, should be called before 
    Replication buffer is sent to the client
*/ 
export function ServerMakePrimitive(pos: Vector3, serializedId: string) {
    let primitive = new Instance('Part');
    primitive.Size = new Vector3(4,4,4);
    primitive.Color = new Color3(0.45, 0, 0);
    primitive.Material = Enum.Material.Neon;
    primitive.Anchored = true;
    primitive.Position = pos; // client sets this as mandatorily passed to the FIRST buffer after its creation
    // during this time writing data for an instance of the same id is impossible, data is read-only
    primitive.AddTag(serializedId);
    primitive.SetAttribute("READ::ONLY", true);
    primitive.Parent = game.Workspace.CurrentCamera;
    return true;
}

// when called begins the loop, custom loops can be created if required, arguments must be passed to the thread when resumption begins
export function CreateNetworkBridge() {
    return coroutine.create(function(setBufferObject: buffer, replicationFrequency: number): void{
         const NetworkCommunicator = new Instance('RemoteEvent');

         while (true) {
            task.wait(replicationFrequency);
            NetworkCommunicator.FireAllClients(setBufferObject);
         }
    });
}

export function CloseNetworkBridge(bridge: thread) {
    assert(bridge, "Failed to close bridge, argument #1 missing or null")
    coroutine.yield(bridge);
    coroutine.close(bridge)

    return true
}

declare module "C:/berry/src/InstanceReplicator";
