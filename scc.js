
var fs = require('fs');
var crypto = require('crypto');
var Mustache = require('mustache');

var getVal = function(cell) {
  return ((cell != undefined) && ('v' in cell)) ? cell.v : null;
}

var render = function(string, config) {
  return Mustache.render(string, config);
}

var getInstruction = function(worksheet, line, config) {
  if (!getVal(worksheet["C"+line])) {
    return null;
  }

  param1 = (typeof getVal(worksheet["D"+line]) === "string") ? render(getVal(worksheet["D"+line]), config) : getVal(worksheet["D"+line]);
  param2 = (typeof getVal(worksheet["E"+line]) === "string") ? render(getVal(worksheet["E"+line]), config) : getVal(worksheet["E"+line]);
  param3 = (typeof getVal(worksheet["F"+line]) === "string") ? render(getVal(worksheet["F"+line]), config) : getVal(worksheet["F"+line]);

  return {
    "name" : getVal(worksheet["A"+line]),
    "desc" : getVal(worksheet["B"+line]),
    "command" : getVal(worksheet["C"+line]),
    "params" : [ param1,
                 param2,
                 param3 ]
  };
}


var loadConfiguration = function(workbook) {
  // Configuration
  var config = {};
  var worksheet = workbook.Sheets["Configuration"];

  for(line=2;line<= 1000;line++) {

    key = getVal(worksheet["A"+line]);
    val = getVal(worksheet["B"+line]);

    if (key != null) {
      if (key in config) {
        console.error( 'Duplicated key #' + key + ':A' + line );
        console.error( 'Fix it to continue. Process aborted!');
        process.exit(1);
      } else {
        config[key] = val;
      }
    }
  }
  return config;
}

var loadCases = function(workbook) {
  var cases = {};
  var sheet_name_list = workbook.SheetNames;
  for ( sheet in sheet_name_list) {
   sheetName = sheet_name_list[sheet]; 
   if (sheetName.indexOf("Case-") == -1) continue;
   cases[sheetName] = {};
   testName = "";
   if (sheetName.toLowerCase().indexOf("case") == 0) {
     
     var worksheet = workbook.Sheets[sheetName];
     for(line=2;line<= 100;line++) {
       test = getInstruction(worksheet, line, config);

       // Ignoring empty lines
       if (test == null) {
         continue;
       }
       testName = (test['name'] != null) ? test['name'] : testName;
       test['name'] = testName;
       if (!(testName in cases[sheetName])) {
         cases[sheetName][testName] = [];  
       }
       console.log([testName, test]);
       cases[sheetName][testName].push(test);
     }
    }
  }
  return cases;
}


var loadData = function(file, callback) {
  var config = {};
  var cases = {};
  var defs = {};

  var filename = file;
  var md5sum = crypto.createHash('md5');

  var s = fs.ReadStream(filename);
  s.on('data', function(d) {
    md5sum.update(d);
  });

  s.on('end', function() {
    var d = md5sum.digest('hex');
    cacheFile = process.env.HOME + '/.feat/data-' + d + ".json";
    fs.stat(cacheFile, function(err, stat) {
      console.log(fs.exists(cacheFile));
      if (!err) {
        console.log("Load from cache");
    		// parse contents as JSON
        var contents = fs.readFileSync(cacheFile, 'utf8');
        data = JSON.parse(contents);

        config = data['config'];
        cases = data['cases'];

      } else {
        console.log("Load from spreadsheet");
        xlsx = require('xlsx');
        workbook = xlsx.readFile(filename);
        config = loadConfiguration(workbook);
        cases  = loadCases(workbook);
        fs.writeFile(cacheFile, JSON.stringify({'config' : config, 'cases' : cases}), function(err){console.log(err);});  
      }
      callback(config, cases);
    });
  });
}

loadData('sample.xlsx', function(config, cases, defs){
  console.log(JSON.stringify(config, null, ' '));
});


