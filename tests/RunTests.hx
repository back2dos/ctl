package ;

class RunTests {
  static function main() {
    var report = 'report.json';

    switch Sys.command('haxe -dce full -cp tests -lib ctl -main Example -neko whatever.n -D ctl-format=json -D ctl-out=$report') {
      case 0: 
        var data:cytotoxic.Data = haxe.Json.parse(sys.io.File.getContent(report));
        switch data {
          case {
            deadTypes: [
              { name: 'Dead' }, 
              { name: 'DeadAbstract' }, 
              { name: 'DeadGeneric' }
            ],
            deadFields: [
              { type: { name: 'Alive' }, fields: [{ name: 'dead' }] }, 
              { type: { name: 'AliveAbstract' }, fields: [{ name: 'dead' }] }, 
              { type: { name: 'AliveGeneric_Int' }, fields: [{ name: 'dead' }] },
              { type: { name: 'AliveGeneric_String' }, fields: [{ name: 'alive' }] }, 
            ]
          }:
            Sys.println('All good!');
          default: 
            Sys.println('Report did not match expectations');
            Sys.exit(500);
        }
      case v: Sys.exit(v);
    }
  }
  
}
