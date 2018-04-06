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