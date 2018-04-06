package cytotoxic;

import haxe.macro.*;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Context;
using StringTools;

class TCell {
  static function fieldsOf(cl:ClassType) {
    var ret = new Map();
    for (f in cl.statics.get().concat(cl.fields.get()))
      switch f.kind {
        case FMethod(MethInline | MethMacro):
        case FMethod(_): ret[f.name] = f;
        default:
      }
    return ret;
  }

  static function name(b:BaseType)
    return b.pack.concat([b.name]).join('.');

  static function unleash() {
    #if (dce == "full")
    if (!Context.defined('ctl-skip')) Context.onGenerate(function (types) {
      var cwd = Sys.getCwd();

      function inCwd(b:BaseType) 
        return !haxe.io.Path.isAbsolute(b.pos.getPosInfos().file);
      
      var oldFields = new Map(),
          generics = new Map();

      for (t in types) switch t {

        case TInst(_.get() => cl = { isExtern: false }, _) if (inCwd(cl)):
          
          switch cl.kind {
            case KGenericInstance(_.get() => cl, _):
              generics[name(cl)] = true;
            default:
          }

          switch fieldsOf(cl) {
            case _.iterator().hasNext() => false:
            case v: oldFields[name(cl)] = v;
          }

        default:
      }

      Context.onAfterGenerate(function () {

        var deadTypes = [],
            deadFields = [];

        function isDead(t:BaseType, ?owner:BaseType) 
          return
            if (owner == null) isDead(t, t);
            else if (oldFields.exists(name(t)) && !t.meta.has(':used'))
              deadTypes.push(owner) > 0;
            else false;

        function classFields(cl:ClassType, ?owner:BaseType) {
          if (owner == null) owner = cl;

          switch oldFields[name(cl)] {
            case null:
            case old: 
              var nu = fieldsOf(cl);
              switch [for (f in old) if (!nu.exists(f.name)) f] {
                case []:
                case dead:
                  deadFields.push({
                    type: owner,
                    fields: dead,
                  });
              }
          }
        }

        for (t in types) switch t {

          case TInst(_.get() => cl = { isExtern: false, kind: KGeneric }, _) if (inCwd(cl))://TODO: deal with generics
            
            if (!generics[name(cl)]) deadTypes.push(cl);

          case TInst(ref = _.get() => cl = { isExtern: false, kind: KNormal | KGenericInstance(_, _) }, _) if (inCwd(cl)):
            
            if (!isDead(cl)) classFields(cl);

          case TInst(_.get() => cl = { isExtern: false, kind: KAbstractImpl(_.get() => a) }, _) if (inCwd(cl)):
            
            if (!isDead(cl, a)) classFields(cl, a);
          
          default:
        }

        if (Context.defined('ctl-warn')) {
          for (t in deadTypes)
            'Unused type'.warning(t.pos);
          for (f in deadFields)
            for (f in f.fields)
              'Unused field'.warning(f.pos);
          return;
        }

        var output = switch Context.definedValue('ctl-out') {
          case null: Sys.print;
          case v: sys.io.File.saveContent.bind(v);
        }

        function render(renderer:Data->String) {
          function pos(p:Position) {
            var s = Std.string(p);
            return s.substring(5, s.length - 1);
          }

          function type(t)
            return { name: name(t), pos: pos(t.pos) };

          output(renderer({
            deadTypes: [for (t in deadTypes) type(t)],
            deadFields: [for (f in deadFields) {
              type: type(f.type),
              fields: [for (f in f.fields) {
                name: f.name,
                pos: pos(f.pos),
              }]
            }],
          }));
        }

        deadTypes.sort(function (a, b) return Reflect.compare(name(a), name(b)));
        deadFields.sort(function (a, b) return Reflect.compare(name(a.type), name(b.type)));

        switch Context.definedValue('ctl-format') {
          case null:
            var indent = '  ';
            var lines = [];
            function out(s:String)
              lines.push(s);

            function pos(o) {
              var ret = Std.string(o.pos).substr(5);
              return ret.substring(0, ret.lastIndexOf(':'));
            }

            function type(t:BaseType)
              return '$indent${name(t)} @ ${pos(t)}';
            if (deadTypes.length > 0)
              out('Dead Types:\n\n'+[for (t in deadTypes) type(t)].join('\n'));
            if (deadFields.length > 0) {
              out('\nPartially Dead Types:');
              for (d in deadFields) {
                out('\n'+type(d.type)+'\n');
                for (f in d.fields)
                  out('$indent$indent${f.name} @ ${pos(f)}');
              }
            }
            output(lines.join('\n') + '\n');
          case 'json':
            render(haxe.Json.stringify.bind(_, null, '  '));
          case 'hx': 
            render(haxe.Serializer.run);
          case v: 'Unsupported format $v'.fatalError(Context.currentPos()); 
        }

      });


    });
    #end
  }
}