describe "cached runInThisContext", ->
  main = null

  beforeEach ->
    main = require("../src/main")

  it "runs arbitrary functions as vm.runInThisContext", ->
    vm = require("vm")
    fn = "(function(a, b, c) { return a + b + c; })"

    expect(
      vm.runInThisContext(fn, "filename")(1, 2, 3)
    ).toBe main.runInThisContext(fn, "filename").result(1, 2, 3)

  it "returns a cache that can be used to speed up future compilations", ->
    fn = "(function(a, b, c) { return a; })"

    nonCached = main.runInThisContext(fn, "filename")
    cached = main.runInThisContextCached(fn, "filename", nonCached.cacheBuffer)

    expect(nonCached.result(1)).toBe(cached.result(1))
    expect(cached.wasRejected).toBe(false)

  it "rejects the cache when it doesn't match the supplied source code", ->
    fn = "(function(a, b, c) { return a + b; })"

    cached = main.runInThisContextCached(fn, "filename", new Buffer("invalid cache"))

    expect(cached.result(10, 20)).toBe(30)
    expect(cached.wasRejected).toBe(true)

  it "doesn't return a cache when the same function gets run 3 or more times within the same context", ->
    # this seems like a v8 optimization
    fn = "(function(a, b, c) { return 42; })"

    expect(main.runInThisContext(fn, "file").cacheBuffer).toBeTruthy()
    expect(main.runInThisContext(fn, "file").cacheBuffer).toBeTruthy()
    expect(main.runInThisContext(fn, "file").cacheBuffer).toBeFalsy()
