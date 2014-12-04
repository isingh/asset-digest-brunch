crypto = require 'crypto'
fs = require 'fs'
glob = require 'glob'
path = require 'path'

class AssetDigest
  brunchPlugin: yes

  constructor: (@config) ->
    # Load some sane defaults
    @options =
      patternForSubstitution: /DIGEST/g
      prefixForSubstitution: ''
      patternForFilesForDigest: null
      manifestPath: 'public/man.json'
      retainOriginal: false

    # Merge the defaults with the config that was provided
    providedConfig = @config.plugins?.assetDigest ? {}
    @options[key] = value for key, value of providedConfig

  onCompile: ->
    @_generateDigestFiles()
    console.log(glob.sync('public/**'))

  # Generate the files in the file system
  _generateDigestFiles: ->
    filesForDigest = @_filesForDigest()
    manifest = @_generateManifest(filesForDigest)
    for originalFileName, newFileName of manifest
      if @options.retainOriginal is true
        # If user specifies retainOriginal then we make a duplicate copy
        # of the file with the new digest name
        @_copyFile(originalFileName, newFileName, @_raiseError)
      else
        # Otherwise we simply rename the file to the digest name
        @_renameFile(originalFileName, newFileName, @_raiseError)

  # Rename a file
  _renameFile: (originalFileName, newFileName, callback) ->
    fs.rename(originalFileName, newFileName, @_raiseError)

  # Asynchronously copy a file
  _copyFile: (originalFileName, newFileName, callback) ->
    callbackCalled = false
    copyDone = (error) ->
      if !callbackCalled
        callback(error)
        callbackCalled = true

    # Input stream
    source = fs.createReadStream(originalFileName)
    source.on("error", copyDone)

    # Output stream
    target = fs.createWriteStream(newFileName)
    target.on("error", copyDone)
    target.on("close", (ex) -> copyDone())

    # Pipe the input to out
    source.pipe(target)

  # Generate the manifest for the files that need to have a digest
  # Save the manifest file if the user specified a path
  _generateManifest: (filesForDigest) ->
    manifest = @_fileDigestMap(filesForDigest)
    if @options.manifestPath?
      fs.writeFile(@options.manifestPath, JSON.stringify(manifest), @_raiseError)
    manifest

  # A hash map of public files that were eligible
  # and the new filename for them
  _fileDigestMap: (filesForDigest) ->
    fileDigestMap = {}
    for file in filesForDigest
      fileDigestMap[file] = @_addDigestToFileName(file, @_digestForFile(file))
    fileDigestMap

  # Get the new name of the file after appending the digest
  # to its original file name
  _addDigestToFileName: (file, digest) ->
    fileExtension = path.extname(file)
    newFileName = "#{path.basename(file, fileExtension)}-#{digest}#{fileExtension}"
    path.join(path.dirname(file), newFileName)

  # All eligible public files that need to be renamed
  _filesForDigest: ->
    filesForDigest = []
    # Get all possible public files
    for file in @_allPublicFiles()
      fileName = path.basename(file, path.extname(file))
      # Ensure the files match the user given pattern
      # and they are not already a digest file perhaps from the previous run
      if @_matchesPattern(fileName, @options.patternForFilesForDigest) && !@_isDigestFile(fileName)
        filesForDigest.push file
    filesForDigest

  # Get the checksum based on the file contents
  _digestForFile: (file) ->
    @_checksum(fs.readFileSync(file).toString())[0..9]

  # Get the checksum of the given string
  # Returns MD5 checksum be default, unless specified
  _checksum: (str, algorithm, encoding) ->
    crypto
      .createHash(algorithm || 'md5')
      .update(str, 'utf8')
      .digest(encoding || 'hex')

  # Check if the input string matches the pattern
  # Return true if the pattern is null
  _matchesPattern: (stringForTest, pattern) ->
    return true unless pattern?
    pattern.test(stringForTest)

  # Check if the file is already a digest file
  # Look for the checksum in the filename
  _isDigestFile: (fileName) ->
    /-[a-fA-F0-9]{10}$/.test fileName

  # Get a list of all the valid public files
  # This is a master list of all files in public folder
  # from which we will reject ineligible files
  _allPublicFiles: ->
    publicFiles = []
    for filename in glob.sync(@_publicPath())
      # Ensure the file exists and is not a directory
      publicFiles.push filename if fs.statSync(filename).isFile()
    publicFiles

  # Get the public path
  _publicPath: ->
    # If the brunch config did not have a public path
    # assume its public
    "#{@config.paths?.public ? 'public'}/**"

  _raiseError: (error) ->
    console.error error if error?

module.exports = AssetDigest
