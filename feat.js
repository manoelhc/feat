// Generated by CoffeeScript 1.10.0
(function() {
  var Feat, base_paths, colors, crypto, feat, feat_home_dir, fs, lineLimit, logtime, mustache, os, phantom, startTime;

  startTime = new Date().getTime() / 1000;

  colors = require('colors');

  console.log(("[" + new Date() + "]").blue);

  os = require('os');

  fs = require('fs');

  crypto = require('crypto');

  mustache = require('mustache');

  phantom = require('phantom');

  lineLimit = 10;

  feat_home_dir = process.env.HOME + "/.feat/commands";

  base_paths = [feat_home_dir, __dirname + "/commands"];

  startTime = new Date().getTime() / 1000;

  logtime = function(msg) {
    var calc, text;
    calc = new Date().getTime() / 1000;
    calc = calc - startTime;
    text = "[" + parseInt(calc) + "s] ";
    return console.log(text.blue, msg);
  };

  Feat = (function() {
    Feat.prototype.on = function(event, func) {
      return this.events[event] = func;
    };

    Feat.prototype.checkCommand = function(command) {
      var cmd_path, file_path, fn, i, len, path;
      cmd_path = '/' + command + '.command';
      file_path = false;
      fn = function(path) {
        var cmd_file;
        cmd_file = path + cmd_path;
        try {
          if (fs.statSync(cmd_file) !== null) {
            return file_path = cmd_file;
          }
        } catch (undefined) {}
      };
      for (i = 0, len = base_paths.length; i < len; i++) {
        path = base_paths[i];
        fn(path);
      }
      return file_path;
    };

    Feat.prototype.getCommand = function(command) {
      var cmd_path, data, obj;
      cmd_path = Feat.prototype.checkCommand(command);
      if (cmd_path) {
        try {
          obj = require(cmd_path);
          data = obj();
          return {
            "call": data.call,
            "func": data.func.toString()
          };
        } catch (undefined) {}
      }
      return false;
    };

    function Feat(file1) {
      var cases, config, defs, file, loadCases, loadConfiguration, md5sum, s;
      this.file = file1;
      this.config = {};
      this.cases = {};
      this.defs = {};
      this.events = {};
      md5sum = crypto.createHash('md5');
      s = fs.ReadStream(this.file);
      file = this.file;
      cases = this.cases;
      defs = this.defs;
      config = this.config;
      loadCases = this.loadCases;
      loadConfiguration = this.loadConfiguration;
      s.on('data', function(d) {
        return md5sum.update(d);
      });
      s.on('end', function(d) {
        var cacheFile;
        d = md5sum.digest('hex');
        cacheFile = process.env.HOME + '/.feat/cache/data-' + d + ".json";
        return fs.stat(cacheFile, function(err, stat) {
          var cache, contents, data, workbook, xlsx;
          if (!err) {
            contents = fs.readFileSync(cacheFile, 'utf8');
            data = JSON.parse(contents);
            config = data['config'];
            cases = data['cases'];
            defs = data['defs'];
            logtime('Using cache once the original spreadsheet has not being changed'.yellow);
            return Feat.prototype.startTest(data);
          } else {
            logtime('*** Starting the magic of parsing spreadsheets ***'.rainbow);
            xlsx = require('xlsx');
            workbook = xlsx.readFile(file);
            logtime('Parsing file '.yellow + file);
            logtime("Loading configuration".yellow);
            loadConfiguration(workbook, config);
            logtime("Loading Cases".yellow);
            loadCases(workbook, cases, config, defs);
            data = {
              'config': config,
              'cases': cases,
              'defs': defs
            };
            cache = JSON.stringify(data, null, '  ');
            logtime("Saving Cache".yellow + " on " + cacheFile.blue);
            return fs.writeFile(cacheFile, cache, function(err) {
              var msg;
              if (err) {
                msg = "Error: " + err;
                logtime(msg.red);
                process.exit(1);
              }
              return Feat.prototype.startTest(data);
            });
          }
        });
      });
    }

    Feat.prototype.loadCases = function(workbook, cases, config, defs) {
      var checkCommand, getCommand, getInstruction, i, lastCase, len, parseCells, parseWorkbook, results, sheet, sheet_name_list;
      if (config === void 0) {
        config = this.config;
      }
      if (defs === void 0) {
        defs = this.defs;
      }
      getInstruction = Feat.prototype.getInstruction;
      checkCommand = Feat.prototype.checkCommand;
      getCommand = Feat.prototype.getCommand;
      lastCase = null;
      parseCells = function(worksheet, line, sheet) {
        var cmd_path, error, msg, obj, test, testName;
        error = false;
        test = getInstruction(worksheet, line, config);
        if (test === null) {
          return null;
        }
        if (test['name'] !== null) {
          testName = test['name'];
        } else {
          testName = lastCase;
        }
        if (testName !== lastCase) {
          msg = "  - Loading test: " + testName;
          logtime(msg.blue);
        }
        lastCase = testName;
        test['name'] = testName;
        if (!(testName in cases[sheet])) {
          cases[sheet][testName] = [];
        }
        cmd_path = checkCommand(test['command']);
        if (cmd_path !== false) {
          msg = cmd_path.green;
        }
        if (msg === false) {
          msg = "Command does not exist".red + ' - Sheet: ' + sheet.blue + '; Column: ' + 'C'.blue + '; Line: ' + line.toString().blue;
        } else {
          msg = "    @command: ".grey + test['command'].yellow + ' - [from: '.grey + cmd_path.grey + ']'.grey;
        }
        logtime(msg);
        if (defs === void 0) {
          defs = {};
        }
        if (defs[test['command']] !== void 0) {
          return;
        }
        obj = getCommand(test['command']);
        if (obj === false) {
          msg = "The command definition for '".red + test['command'].white + "' (from ".red + cmd_path.yellow + ") cannot be loaded due to a malformed JSON format".red;
          logtime("      " + msg);
          process.exit(1);
        }
        defs[test['command']] = obj;
        logtime(msg.gray);
        if (error) {
          process.exit(1);
        }
        return cases[sheet][testName].push(test);
      };
      parseWorkbook = function(sheet) {
        var i, line, msg, ref, results, testName, worksheet;
        if (sheet.indexOf("Case-") === -1) {
          return null;
        }
        msg = " * Loading Case " + sheet.substring(5);
        logtime(msg.green);
        cases[sheet] = {};
        testName = "";
        if (sheet.toLowerCase().indexOf("case") === 0) {
          worksheet = workbook.Sheets[sheet];
          results = [];
          for (line = i = 2, ref = lineLimit; 2 <= ref ? i <= ref : i >= ref; line = 2 <= ref ? ++i : --i) {
            results.push(parseCells(worksheet, line, sheet));
          }
          return results;
        }
      };
      sheet_name_list = workbook.SheetNames;
      results = [];
      for (i = 0, len = sheet_name_list.length; i < len; i++) {
        sheet = sheet_name_list[i];
        results.push(parseWorkbook(sheet));
      }
      return results;
    };

    Feat.prototype.loadConfiguration = function(workbook, config) {
      var getVal, i, line, parseCells, ref, results, worksheet;
      if (config === void 0) {
        config = this.config;
      }
      getVal = Feat.prototype.getVal;
      worksheet = workbook.Sheets["Configuration"];
      parseCells = function(line) {
        var key, msg, val;
        key = getVal(worksheet["A" + line], config);
        val = getVal(worksheet["B" + line], config);
        if (key !== null) {
          if (key in config) {
            msg = 'ERROR: Duplicated key ' + key + ' (Configuration tab:A' + line + ')';
            logtime(msg.red);
            logtime('ERROR: Fix it to continue. Process aborted!'.red);
            return process.exit(1);
          } else {
            msg = " Setting " + key + " = " + val;
            logtime(msg.green);
            return config[key] = val;
          }
        }
      };
      results = [];
      for (line = i = 2, ref = lineLimit; 2 <= ref ? i <= ref : i >= ref; line = 2 <= ref ? ++i : --i) {
        results.push(parseCells(line));
      }
      return results;
    };

    Feat.prototype.getInstruction = function(worksheet, line, config) {
      var getVal, param1, param2, param3, ret;
      if (config === void 0) {
        config = this.config;
      }
      getVal = Feat.prototype.getVal;
      if (getVal(worksheet["C" + line]) === null) {
        return null;
      }
      param1 = getVal(worksheet["D" + line], config);
      param2 = getVal(worksheet["E" + line], config);
      param3 = getVal(worksheet["F" + line], config);
      ret = {
        "name": getVal(worksheet["A" + line], config),
        "desc": getVal(worksheet["B" + line], config),
        "command": getVal(worksheet["C" + line], config),
        "params": [param1, param2, param3]
      };
      return ret;
    };

    Feat.prototype.getVal = function(cell, config) {
      if (config === void 0) {
        config = this.config;
      }
      if (cell !== void 0 && 'v' in cell) {
        if (typeof cell.v === 'string') {
          return Feat.prototype.render(cell.v, config);
        } else {
          return cell.v;
        }
      } else {
        return null;
      }
    };

    Feat.prototype.render = function(string, config) {
      return mustache.render(string, config);
    };

    Feat.prototype.startTest = function(data) {
      var func, funcs;
      funcs = {};
      for (func in data['defs']) {
        funcs[func] = {
          func: eval('(' + data['defs'][func]['func'] + ')'),
          call: data['defs'][func]['call']
        };
      }
      return phantom.create(function(ph) {
        ph.createPage(function(page) {
          var c, results;
          global.featPage = page;
          results = [];
          for (c in data['cases']) {
            results.push((function(c) {
              var results1, t;
              results1 = [];
              for (t in data['cases'][c]) {
                results1.push((function(t) {
                  var results2, test, tests;
                  tests = data['cases'][c][t];
                  results2 = [];
                  for (test in tests) {
                    results2.push((function(test) {
                      return console.log(test);
                    })(test));
                  }
                  return results2;
                })(t));
              }
              return results1;
            })(c));
          }
          return results;
        });
        return ph.exit();
      });
    };

    return Feat;

  })();

  feat = new Feat('sample.xlsx');

}).call(this);
