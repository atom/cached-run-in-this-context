const main = require('..')
const vm = require('vm')

describe('cached runInThisContext', () => {
  it('runs arbitrary functions as vm.runInThisContext does', () => {
    const fn = '(function(a, b, c) { return a + b + c; })'

    expect(
      vm.runInThisContext(fn, 'filename-1')(1, 2, 3)
    ).toBe(
      main.runInThisContext(fn, 'filename-1').result(1, 2, 3)
    )
  })

  it('throws an exception when the code is not valid', () => {
    const fn = '(function(a, b, c) { an arbitrary error @$%^* })'

    expect(() => main.runInThisContext(fn, 'file-with-errors')).toThrow()
  })

  it('returns a cache that can be used to speed up future compilations', () => {
    const fn = '(function(a, b, c) { return a; })'

    const nonCached = main.runInThisContext(fn, 'filename-2')
    const cached = main.runInThisContextCached(fn, 'filename-2', nonCached.cacheBuffer)

    expect(nonCached.result(1)).toBe(cached.result(1))
    expect(cached.wasRejected).toBe(false)
  })

  it('rejects the cache when the provided buffer is invalid', () => {
    const fn = '(function(a, b, c) { return a + b; })'

    const cached = main.runInThisContextCached(fn, 'filename', new Buffer('invalid cache'))

    expect(cached.result(10, 20)).toBe(30)
    expect(cached.wasRejected).toBe(true)
  })

  it('runs the cached function when compiling a function that is similar to the cached one', () => {
    const fn1 = '(function(a, b, c) { return c + a; })'
    const fn2 = '(function(a, b, c) { return b + a; })'

    const {cacheBuffer} = main.runInThisContext(fn1, 'filename')
    const cached = main.runInThisContextCached(fn2, 'filename', cacheBuffer)

    expect(cached.result(10, 20, 30)).toBe(40)
    expect(cached.wasRejected).toBe(false)
  })

  it('rejects the cache when compiling a function that is not sufficiently similar to the cached one', () => {
    const fn1 = '(function() { return 50; })'
    const fn2 = '(function(a, b, c) { return a + c; })'

    const {cacheBuffer} = main.runInThisContext(fn1, 'filename')
    const cached = main.runInThisContextCached(fn2, 'filename', cacheBuffer)

    expect(cached.result(10, 20, 30)).toBe(40)
    expect(cached.wasRejected).toBe(true)
  })
})
