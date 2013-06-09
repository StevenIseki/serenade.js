class Map
  constructor: (array) ->
    @map = {}
    @put(index, element) for element, index in array

  isMember: (element) ->
    @map[hash(element)]?[0].length > 0

  indexOf: (element) ->
    @map[hash(element)]?[0]?[0]

  put: (index, element) ->
    existing = @map[hash(element)]
    @map[hash(element)] = if existing
      [existing[0].concat(index).sort((a, b) -> a - b), element]
    else
      [[index], element]

  remove: (element) ->
    @map[hash(element)]?[0].shift?()

Transform = (from=[], to=[]) ->
  operations = []
  to = to.map((e) -> e)
  targetMap = new Map(to)

  remove = ->
    result = []
    for element in from
      if targetMap.isMember(element)
        result.push(element)
      else
        operations.push(type: "remove", index: result.length)
      targetMap.remove(element)
    result

  insert = (cleaned) ->
    result = cleaned.map((e) -> e)
    cleanedMap = new Map(cleaned)

    for element, index in to
      unless cleanedMap.isMember(element)
        operations.push(type: "insert", index: index, value: element)
        result.splice(index, 0, element)
      cleanedMap.remove(element)
    result

  swap = (complete) ->
    completeMap = new Map(complete)
    for actual, indexActual in complete
      wanted = to[indexActual]

      if actual isnt wanted
        indexWanted = completeMap.indexOf(wanted)
        completeMap.remove(actual)
        completeMap.remove(wanted)
        completeMap.put(indexWanted, actual)
        complete[indexActual] = wanted
        complete[indexWanted] = actual
        operations.push(type: "swap", index: indexActual, with: indexWanted)
      else
        completeMap.remove(actual)

  swap(insert(remove()))
  operations
