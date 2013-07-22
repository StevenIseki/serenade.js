---
layout: default
title: Serenade.defineEvent
reference: true
---

Events can be useful for any number of things. Serenade uses them internally to
automatically update the DOM when your model data changes. Serenade provides
`Serenade.defineEvent`, which can be used to declare that an object has an
event:

``` javascript
var object = {}
Serenade.defineEvent(object, "update");

object.update.bind(function() {
  console.log("updated!");
});

object.update.trigger()
```

Unlike other implementations of events, `Serenade.defineEvent` does not add
`bind` and `trigger` methods directly to the object. Instead, defining an event
with a name creates a property with that name on the object, through which the
event can be accessed. This means that `Serenade.defineEvent` can be used on
any object.

## Signature

``` javascript
Serenade.defineEvent(object, name, options)
```

## Options

### bind: function(fn)

Takes a function which is called whenever a new listener is attached to this
event. Takes the listener function as an argument.

### unbind: function(fn)

Takes a function which is called whenever a listener is detached from this
event. Takes the listener function as an argument.

### async: true|false

When this option is `false` and `trigger` is called, all listeners attached to
the event are executed immediately, and `trigger` blocks until this execution
is finished. If the option is `true` then `trigger` returns immediately and is
executed asynchronously.

If this option is not given, the value is taken from `Serenade.async`.

### timeout: Number

If `async` is true, this option causes all listeners to be called
the given amount of milliseconds after `trigger` is called.

If this option is set to 50 and the event is triggered, and then triggered
again after 30ms, both triggers will resolve in the order they were triggered
50ms after the *first* trigger occured. You will probably want to use the
`optimize` option to optimize both of these triggers into a single invocation.
This way, you can rate limit at what rate the event is triggered.

See also the `buffer` option.

### buffer: true|false

If the `timeout` option is set to 50, and this option is set to `true`, and the
event is triggered, and then triggered again after 30ms, both triggers will
resolve in the order they were triggered 50ms after the *last* trigger occured.
This means that subsequent triggering of the event will reset the timeout.
This is useful for events which are usually idle, but when triggered occur
often in quick succession.

Think for example of resizing some element via dragging the mouse, such an
event might occur very often, but you might not want other things which are
dependent on the interaction to only be affected after the dragging stops.

Again, you will probably want to use the `optimize` option to optimize both of
these triggers into a single invocation.

### animate: true

When true, this option causes behaviour similar to the `timeout` option, except
that it uses `requestAnimationFrame`.

Note that this option requires the unprefixed versions of
`requestAnimationFrame` and `cancelAnimationFrame`.  These are currently not
supported by any browser, so you will need to shim them.

### optimize: function(queue) { return args }

When an event is triggered and the `async` option is `true`, it is pushed onto
a queue, this queue is an array of arrays, where each item in the array contains
the arguments passed to `trigger`.

When the event eventually resolves, the function given to the `optimize` option
is called with the queue as its argument. It is expected to return an array
of arguments which are then passed to all listeners.

Effectively, optimize can reduce a queue of triggered events into a single
invocation of the event. This way, calls to expensive listeners can be reduced
if the event is triggered many times in quick succession.

Consider this highly optimized logging event:

``` javascript
var object = {}
Serenade.defineEvent(object, "log", {
  async: true,
  optimize: function(queue) {
    return [queue.map(function(item) { return item[0] }).join("")];
  }
});
object.log.bind(function(string) { console.log(string) });

object.log.trigger("foo");
object.log.trigger("bar");
```

Eventually, a single log message "foobar" will appear in the log.

## Methods

### bind(function(args...))

Attach a function as a listener to this event, it will be triggered when
`trigger` is called and given whatever arguments were passed to `trigger`.

### unbind(function(args...))

Detach a function from this event, it will no longer be called when `trigger`
is called.

### trigger(args...)

Trigger this event. Will loop through all listeners attached via `bind` or
`one` and call them, passing in the given arguments. Listeners are called in
the context of the object the event is attached to, so `this` points to the
object within the callback function.

### one(function(args...))

Attach a function as a listener to this event, the next time that `trigger` is
called, the listener function is called and given whatever arguments were
passed to `trigger`. After that, the function is detached from the event, and
will no longer be called when `trigger` is called.

### resolve()

When the event is asynchronous and has accumulated a queue of events, `resolve`
immediately optimizes and executed that queue. `resolve` is synchronous and
will block until all attached listeners have executed.

### queue

Returns the current queue of invocations. An array of arrays, where each item
is a list of arguments previously passed to `trigger`. Only relevant for
asynchronous events.

### listeners

Returns an array of all functions currently attached as listeners to this
event.
