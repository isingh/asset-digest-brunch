mock = require 'mock-fs'

setupFakeFileSystem = () ->
  mock(
    public:
      'index.html': 'Home Page' # cfe6e34a4c
      js:
        'app.js': 'App JS' # 82019350ea
        'vendor.js': 'some vendored JS' # 934e42cab5
        'app-a1b2c3d4e5.js': 'an existing file'

  )

destroyFakeFileSystem = () ->
  mock.restore()


describe 'AssetDigest', ->
  assetDigest = null

  beforeEach ->
    assetDigest = new AssetDigest({})

  it 'is an object', ->
    expect(typeof assetDigest).to.eq('object')

  it 'should have default configs', ->
    expect(assetDigest.options).to.include.keys(
      'patternForSubstitution',
      'prefixForSubstitution',
      'patternForFilesForDigest',
      'manifestPath',
      'retainOriginal'
    )

  it 'uses the user provided config', ->
    config =
      plugins:
        assetDigest:
          patternForSubstitution: /NEWPATTERN/g
          prefixForSubstitution: 'http://cdn.example.com'
          patternForFilesForDigest: /COPYPATTERN/g
          manifestPath: 'manifest.json'
          retainOriginal: true
    assetDigest = new AssetDigest(config)
    expect(assetDigest.options).to.deep.equal(config.plugins.assetDigest)

  describe 'compile with defaults', ->
    beforeEach (done) ->
      setTimeout( ->
        setupFakeFileSystem()
        assetDigest.onCompile()
        done()
      , 500)

    afterEach ->
      destroyFakeFileSystem()

    it 'does something', ->
      null



