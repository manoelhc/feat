startTime = new Date().getTime() / 1000
colors   = require 'colors'
console.log ("[" + new Date() + "]").blue

os       = require 'os'
fs       = require 'fs'
crypto   = require 'crypto'
mustache = require 'mustache'
#phantom  = require 'phantom'
Spooky   = require 'spooky'

spookyConfig =
  child:
    transport: 'http'
  casper:
    logLevel:  'debug',
    verbose:   true

lineLimit = 10

console.log process.env.PATH

feat_home_dir = process.env.HOME + "/.feat"

fs.mkdirSync(feat_home_dir) if not fs.existsSync(feat_home_dir)
fs.mkdirSync(feat_home_dir + "/cache") if not fs.existsSync(feat_home_dir + "/cache")

base_paths = [feat_home_dir + "/commands",  __dirname + "/commands"]

startTime = new Date().getTime() / 1000

logtime = (msg)->
  calc = new Date().getTime() / 1000
  calc = calc - startTime
  text = "[" + parseInt(calc) + "s] "
  console.log text.blue, msg

class Feat
  on: (event, func)->
    @events[event] = func

  checkCommand: (command)->
    cmd_path = '/' + command + '.command'
    file_path = false
    for path in base_paths
      do (path)->
        cmd_file = path + cmd_path
        try
          file_path = cmd_file if fs.statSync(cmd_file) != null

    return file_path

  getCommand: (command)->
    cmd_path = Feat::checkCommand(command)
    if cmd_path
      try
        obj = require(cmd_path) # JSON.parse(fs.readFileSync(cmd_path, 'utf8'))
        data = obj()
        return { "call" : data.call, "func" : data.func.toString() }
    return false

  constructor: (@file) ->
    @config = {}
    @cases  = {}
    @defs   = {}
    @events = {}

    md5sum = crypto.createHash('md5')

    s = fs.ReadStream(@file)

    file = @file
    cases = @cases
    cases['@order'] = []
    defs = @defs
    config = @config
    loadCases = @loadCases
    loadConfiguration = @loadConfiguration

    s.on 'data', (d)->
      md5sum.update(d)
    s.on 'end', (d)->
      d = md5sum.digest('hex')
      cacheFile = process.env.HOME + '/.feat/cache/data-' + d + ".json"

      fs.stat cacheFile, (err, stat)->
        if not err
          contents = fs.readFileSync(cacheFile, 'utf8')

          data = JSON.parse(contents)

          config = data['config']
          cases  = data['cases']
          defs   = data['defs']

          logtime 'Using cache once the original spreadsheet has not being changed'.yellow
          Feat::startTest data

        else
          logtime '*** Starting the magic of parsing spreadsheets ***'.rainbow
          xlsx   = require('xlsx')
          workbook = xlsx.readFile(file)
          logtime 'Parsing file '.yellow + file
          logtime "Loading configuration".yellow
          loadConfiguration workbook, config

          logtime "Loading Cases".yellow
          loadCases workbook, cases, config, defs

          data =
             'config' : config
             'cases'  : cases
             'defs'   : defs

          cache = JSON.stringify(data, null, '  ')
          logtime "Saving Cache".yellow + " on " + cacheFile.blue

          fs.writeFile cacheFile, cache, (err)->
            if err
              msg = "Error: " + err
              logtime msg.red
              process.exit 1
            Feat::startTest data


  loadCases : (workbook, cases, config, defs)->
    config = @config if config is undefined
    defs   = @defs if defs is undefined

    getInstruction = Feat::getInstruction
    checkCommand   = Feat::checkCommand
    getCommand     = Feat::getCommand

    lastCase = null
    # Ver testName
    parseCells = (worksheet, line, sheet)->
      error = false
      test = getInstruction(worksheet, line, config)

      # Ignoring empty lines
      return null if test is null

      if test['name'] isnt null
        testName = test['name']
      else
        testName = lastCase
      if testName != lastCase
        msg  = "  - Loading test: " + testName
        logtime msg.blue

      lastCase = testName
      test['name'] = testName

      if testName not of cases[sheet]
        cases[sheet][testName] = []
        cases[sheet]['@order'].push(testName)


      # Checking if command exists
      cmd_path = checkCommand(test['command'])
      msg = cmd_path.green if cmd_path != false

      if msg == false
        msg = "Command does not exist".red + ' - Sheet: ' + sheet.blue + '; Column: ' + 'C'.blue + '; Line: ' + line.toString().blue
      else
        msg  = "    @command: ".grey + test['command'].yellow + ' - [from: '.grey + cmd_path.grey + ']'.grey

      logtime msg

      defs = {} if defs == undefined

      if defs[test['command']] != undefined
        return

      obj = getCommand(test['command'])

      if obj == false
        msg = "The command definition for '".red + test['command'].white + "' (from ".red + cmd_path.yellow + ") cannot be loaded due to a malformed JSON format".red
        logtime "      " + msg
        process.exit 1

      defs[test['command']] = obj



      logtime msg.gray
      process.exit 1 if error
      cases[sheet][testName].push(test)

    parseWorkbook = (sheet)->

      return null if sheet.indexOf("Case-") is -1

      msg = " * Loading Case " + sheet.substring(5)
      logtime msg.green
      cases['@order'].push(sheet)
      cases[sheet] = { '@order' : [] }
      testName = ""

      if sheet.toLowerCase().indexOf("case") is 0
        worksheet = workbook.Sheets[sheet]
        parseCells worksheet, line, sheet for line in [2..lineLimit]

    sheet_name_list = workbook.SheetNames
    parseWorkbook sheet for sheet in sheet_name_list

  loadConfiguration: (workbook, config)->
    if config is undefined
      config = @config
    getVal = Feat::getVal

    worksheet = workbook.Sheets["Configuration"]

    parseCells = (line)->
      key = getVal(worksheet["A" + line], config)
      val = getVal(worksheet["B" + line], config)
      if key isnt null
        if key of config
          msg = 'ERROR: Duplicated key ' + key + ' (Configuration tab:A' + line + ')'
          logtime msg.red
          logtime 'ERROR: Fix it to continue. Process aborted!'.red
          process.exit 1
        else
          msg = " Setting " +key + " = " + val
          logtime msg.green
          config[key] = val

    parseCells line for line in [2..lineLimit]


  getInstruction : (worksheet, line, config)->
    if config is undefined
      config = @config
    getVal = Feat::getVal
    return null if getVal(worksheet["C" + line]) == null

    param1 = getVal(worksheet["D"+line], config)
    param2 = getVal(worksheet["E"+line], config)
    param3 = getVal(worksheet["F"+line], config)

    desc = getVal(worksheet["B"+line], config)
    desc = "Empty description, please describe this step!" if desc == null

    ret =
      "name"    : getVal(worksheet["A"+line], config),
      "desc"    : desc,
      "command" : getVal(worksheet["C"+line], config),
      "params"  : [ param1, param2, param3 ]

    return ret

  getVal: (cell, config)->
    if config is undefined
      config = @config
    if cell isnt undefined and 'v' of cell
      if typeof cell.v is 'string'
        return Feat::render(cell.v, config)
      else
        return cell.v
    else
      return null

  render: (string, config) ->
    return mustache.render(string, config)

  startTest: (data)->

    logtime " -- Testing Web Browser --".yellow

    funcs = {};
    for func of data['defs']
      funcs[func] = { func : eval('(' + data['defs'][func]['func'] + ')'), call: data['defs'][func]['call'] }


    cases = data['cases']
    defs = data['defs']

    i = -1
    currentTask = 0
    params = []
    inters = []

    for c in cases['@order']
      logtime "Running test case ".yellow + " " + c.white
      logtime "  >> Starting a new browser session <<".green

      phantom = require 'phantom'
      loading = true

      phantom.create (ph) ->
        ph.createPage (page) ->
          featTest = ()->
            for testName in cases[c]['@order']
              console.log testName
              test = cases[c][testName]
              for step in test
                i++
                desc = step.desc + "    >>>   (" + step.command + "[" +step.params.join(', ')+ "]"
                desc = "  >> ".gray + desc.gray
                desc = desc.replace("'","\'")

                fn = defs[step['command']]['func']

                params[i] = step.params;

                code = "var fn="+ fn + ";fn(page, params["+i+"][0], params["+i+"][1], params["+i+"][2], params["+i+"][3])"
                code = "(function(){if (currentTask !== " + i + ") { return; }; logtime('" + desc + "'); " + code + ";clearInterval(inters["+i+"]);})"

                task = eval(code)

                inters[i] = setInterval(task, 200)
              i++
              code = 'pid = '+i+';if(currentTask >= pid && ph){currentTask++;ph.exit();clearInterval(inters[pid])};'
              exitTask = eval('(function(){' + code + '})')
              inters[i] = setInterval(exitTask, 1000)

          #featTest()

          page.onConsoleMessage = (msg)->
            console.log(msg);

          #injectJquery = ()->
            #script = document.createElement('script');
            #script.type = 'text/javascript'
            #script.src = 'http://ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js'
            #document.body.appendChild script
            #document.title = 'Injecting'
            #return document.title
          featTest()
          #page.evaluate injectJquery, featTest

#          else
#            logtime "jQuery inject failed!"
#            ph.exit()
#            process.exit 1



feat = new Feat 'sample.xlsx'
