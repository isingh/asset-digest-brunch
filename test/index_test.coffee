describe 'AssetDigest', ->
  assetDigest = null

  beforeEach ->
    assetDigest = new AssetDigest({})

  it 'is an object', ->
    expect(typeof assetDigest).to.eq('object')

