module mango_engine.input;

import mango_engine.mango;
import mango_engine.game;
import mango_engine.event.core;

import std.concurrency;
import std.container.dlist;
import std.exception;

import derelict.glfw3.glfw3;

immutable size_t INPUT_TYPE_KEY;
immutable size_t INPUT_TYPE_MOUSE;

/// Represents data for a given input type.
abstract class InputData {

}

class KeyInputData : InputData {
    immutable size_t key;
    immutable size_t state;

    this(in size_t key, in size_t state) @safe nothrow {
        this.key = key;
        this.state = state;
    }
}

/++
    This struct is message-passed to the InputManager thread,
    where it is then handled in it's corresponding hook.
+/
package struct InputEventMessage {
    /// The type of InputEvent
    shared size_t type;
    /// The input data
    shared InputData data;
}

/// The InputHook delegate, which is called when input is received.
public alias InputHook = void delegate(size_t type, InputData data) @system;

enum ThreadSignal {
    SIGNAL_STOP
}

/++
    Handles input and processes them in
    InputHooks.
+/
class InputManager {
    private shared GameManager _game;
    private shared Tid _threadTid;
    private shared bool _running = false;

    private shared InputHook[] hooks;
    private DList!InputEventMessage events;

    @property GameManager game() @trusted nothrow { return cast(GameManager) _game; }
    @property bool running() @safe nothrow { return _running; }

    this(GameManager game) @system {
        this._game = cast(shared) game;
        
        this.events = DList!InputEventMessage();
        this._threadTid = cast(shared) spawn(&spawnInputThread, cast(shared) this);

        this.game.eventManager.registerEventHook(EngineCleanupEvent.classinfo.name,
            EventHook((Event e) {
                this.stopInputThread();  
            }, false) 
        );
    }

    void registerInputHook(InputHook hook) @safe {
        synchronized(this) {
            this.hooks ~= cast(shared) hook;
        }
    }

    package void run() @system {
        enforce(!this.running, new Exception("The InputManager Thread is already running!"));

        this._running = true;

        GLOBAL_LOGGER.logDebug("Input Thread started.");

        while(this.running) {
            import std.datetime;

            receiveTimeout(1.msecs,
                (ThreadSignal signal) {
                    switch(signal) {
                        case ThreadSignal.SIGNAL_STOP:
                            this._running = false;
                            return;
                        default:
                            GLOBAL_LOGGER.logDebug("Unknown signal");
                            break;
                    }
                },
                &handleInputEventMessage,
            );

            if(!this.events.empty) {
                InputEventMessage msg = this.events.front;
                this.events.removeFront();

                handleInputEventMessage(msg);
            }
        }

        GLOBAL_LOGGER.logDebug("Input Thread exiting.");
    }

    private void handleInputEventMessage(InputEventMessage m) @trusted {
        synchronized(this) {
            foreach(hook; this.hooks) {
                hook(cast(size_t) m.type, cast(InputData) m.data);
            }
        }
    }

    void sendInputEventMessage(size_t type, InputData data) @system nothrow {
        this.events.insertBack(InputEventMessage(type, cast(shared) data));
        //send((cast(Tid) this._threadTid), new InputEventMessage(type, cast(shared) data));
    }

    /// Sends a THREAD_SIGNAL_STOP signal to the Thread.
    void stopInputThread() @system {
        prioritySend((cast(Tid) this._threadTid), ThreadSignal.SIGNAL_STOP);
    }
}

private void spawnInputThread(shared InputManager manager) @system {
    import core.thread : Thread;

    Thread.getThis().name = "InputManager";

    try {
        (cast(InputManager) manager).run();
    } catch(OwnerTerminated e) {
        GLOBAL_LOGGER.logDebug("Input Thread crashed (Main Thread terminated).");
    } catch(Exception e) {
        GLOBAL_LOGGER.logError("Input Thread has crashed!");
        GLOBAL_LOGGER.logException("Exception in Input Thread! ", e);
    }
}