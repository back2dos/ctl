package ;

class Example {
  static function main() {
    new Alive().alive();
    new AliveGeneric<Int>().alive();
    new AliveGeneric<String>().dead();
    new AliveAbstract().alive();    
  }
}

class Alive {
  public function new() {}
  public function alive() trace("alive");
  public function dead() trace("dead");
}

class Dead {
  public function new() {}
  public function alive() trace("alive");
  public function dead() trace("dead");
}

abstract DeadAbstract(String) {

}

abstract AliveAbstract(String) {
  public function new() this = "alive";
  public inline function alive() trace("alive");
  public function dead() trace("dead");

}


@:generic class DeadGeneric<T> {
  public function new() {}
}

@:generic class AliveGeneric<T> {
  public function new() {}
  public function alive() trace("alive");
  public function dead() trace("dead");
  
}
