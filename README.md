# Cytotoxic T cells for your codebase

Usage: `-lib ctl`

Adding this library to your build will generate DCE reports, i.e. which classes are entirely eliminated, and on partially eliminated classes, which fields are eliminated.

Configuration:

- `-D ctl-skip`: Skips reporting. Reporting is also skipped unless you use `-dce full`.
- `-D ctl-warn`: Rather than producing a report, the lib will raise warnings at the relevant types/fields
- `-D ctl-out=<file>`: Redirect reporting to file.
- `-D ctl-format=<json|hx>`: Outputs as either JSON string or haxe serialized string of type `cytotoxic.Data`: 

```haxe
package cytotoxic;

typedef Item = {
  name:String,
  pos:String,
}

typedef Data = {
  deadTypes: Array<Item>,
  deadFields: Array<{
    type: Item,
    fields: Array<Item>
  }>,
}
```