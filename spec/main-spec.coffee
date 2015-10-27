describe "cached runInThisContext", ->
  main = null

  beforeEach ->
    main = require("../src/main")

  it "runs arbitrary functions as vm.runInThisContext does", ->
    fn = "(function(a, b, c) { return a + b + c; })"

    expect(
      require("vm").runInThisContext(fn, "filename-1")(1, 2, 3)
    ).toBe main.runInThisContext(fn, "filename-1").result(1, 2, 3)

  it "throws an exception when the code is not valid", ->
    fn = "(function(a, b, c) { an arbitrary error @$%^* })"

    expect(-> main.runInThisContext(fn, "file-with-errors")).toThrow()

  it "returns a cache that can be used to speed up future compilations", ->
    fn = "(function(a, b, c) { return a; })"

    nonCached = main.runInThisContext(fn, "filename-2")
    cached = main.runInThisContextCached(fn, "filename-2", nonCached.cacheBuffer)

    expect(nonCached.result(1)).toBe(cached.result(1))
    expect(cached.wasRejected).toBe(false)

  it "rejects the cache when it doesn't match the supplied source code", ->
    fn = "(function(a, b, c) { return a + b; })"

    cached = main.runInThisContextCached(fn, "filename", new Buffer("invalid cache"))

    expect(cached.result(10, 20)).toBe(30)
    expect(cached.wasRejected).toBe(true)

  it "doesn't return a cache when the same function gets run 3 or more times within the same context", ->
    # this spec documents what seems like a v8 optimization
    fn = "(function(a, b, c) { return 42; })"

    expect(main.runInThisContext(fn, "file").cacheBuffer).toBeTruthy()
    expect(main.runInThisContext(fn, "file").cacheBuffer).toBeTruthy()
    expect(main.runInThisContext(fn, "file").cacheBuffer).toBeFalsy()
