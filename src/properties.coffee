{Serenade} = require './serenade'
{Collection} = require './collection'
{Events} = require './events'
{pairToObject, serializeObject, extend} = require './helpers'

prexix = "_prop_"
exp = /^_prop_/

Serenade.Properties =
  property: (name, options={}) ->
    @[prexix + name] = options
    @[prexix + name].name = name
    Object.defineProperty @, name,
      get: -> Serenade.Properties.get.call(this, name)
      set: (value) -> Serenade.Properties.set.call(this, name, value)
    if typeof(options.serialize) is 'string'
      @property(options.serialize, get: (-> @get(name)), set: ((v) -> @set(name, v)))

  collection: (name, options) ->
    @property name,
      get: ->
        unless @attributes[name]
          @attributes[name] = new Collection([])
          @attributes[name].bind 'change', =>
            @_triggerChangesTo([name])
        @attributes[name]
      set: (value) ->
        @get(name).update(value)

  set: (attributes, value) ->
    attributes = pairToObject(attributes, value) if typeof(attributes) is 'string'

    keys = []
    for name, value of attributes
      keys.push(name)
      @attributes or= {}
      if @[prexix + name]?.set
        @[prexix + name].set.call(this, value)
      else
        @attributes[name] = value
    @_triggerChangesTo(keys)

  get: (name) ->
    @attributes or= {}
    if @[prexix + name]?.get
      @[prexix + name].get.call(this)
    else
      @attributes[name]

  format: (name) ->
    format = @[prexix + name]?.format
    if typeof(format) is 'string'
      Serenade._formats[format].call(this, @get(name))
    else if typeof(format) is 'function'
      format.call(this, @get(name))
    else
      @get(name)

  serialize: ->
    serialized = {}
    for name, options of this when name.match(exp)
      if typeof(options.serialize) is 'string'
        serialized[options.serialize] = serializeObject(@get(options.name))
      else if typeof(options.serialize) is 'function'
        [key, value] = options.serialize.call(@)
        serialized[key] = serializeObject(value)
      else if options.serialize
        serialized[options.name] = serializeObject(@get(options.name))
    serialized

  _triggerChangesTo: (changedProperties) ->
    normalizeDeps = (deps) -> [].concat(deps)
    checkDependenciesFor = (toCheck) =>
      for name, property of this when name.match(exp) and property.dependsOn
        if toCheck in normalizeDeps(property.dependsOn) and property.name not in changedProperties
          changedProperties.push(property.name)
          checkDependenciesFor(property.name)
    checkDependenciesFor(prop) for prop in changedProperties

    changes = {}
    for name in changedProperties
      value = @get(name)
      @trigger("change:#{name}", value)
      changes[name] = value
    @trigger("change", changes)

extend(Serenade.Properties, Events)
