import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'globals.dart';

/*
эбаут

common speed up depends on efficient
sub size depend on height
left - right corners blocks
после 10 сбитых + рандом субмарина
for 2-3 players - compare effectivity per time
*/

class Battle extends StatefulWidget {
  const Battle({Key? key}) : super(key: key);

  @override
  State<Battle> createState() => _BattleState();
}

class Bomb {
  double x=0, y=0, vx=0, vy=4, height=30, width=6;

  @override
  String toString() {
    return 'Bomb x=$x y=$y';
  }
}

class WarShip {
  double x=0, y=25;
  double vx=5, vy=0;
  double width=80, height=60;
  bool isDamaged = false;
  double warShipBoomTimer = 0, warShipMaxBoomTimer = 3;

  @override
  String toString() {
    return 'WarShip x=$x y=$y width $width height $height\n'
        'vx=$vx vy=$vy isDamaged=$isDamaged';
  }
}

class Sub {
  double x=0, y=0, angle=90, reload=0;
  double vx=-1, vy=2;
  bool isDamaged = false;
  double width = 70, height = 40; //112x69
  double boomTimer = 0;
  String name = 'tank_t34';

  @override
  String toString() {
    return 'Submarine x=$x y=$y angle=$angle reload=$reload\n'
        'vx=$vx vy=$vy isDamaged=$isDamaged';
  }
}

class _BattleState extends State<Battle> {
  WarShip warShip = WarShip();
  List <Bomb> bombs = [];
  List <Sub> subs = [];
  Size fieldSize = const Size(0,0);
  bool isMoveRight = false, isMoveLeft = false;
  double bombReloadTime = 4, bombReloadTimer = 0;
  int refreshPeriod = 30;
  double blueHeight = 0, yellowHeight = 0;
  double speedUpRate = 1;
  int curMaxSubs = 1;

  var rng = Random();
  final dronePlayer = AudioPlayer();
  final tankPlayer = AudioPlayer();
  final bombStartPlayer = AudioPlayer();
  final bombBoomPlayer = AudioPlayer();
  final warShipBoomPlayer = AudioPlayer();

  @override
  void initState() {
    Future.delayed(Duration(milliseconds: refreshPeriod), _refresh);
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _startDroneSound();
    _prepareOtherSounds();
  }

  @override
  void dispose() {
    dronePlayer.dispose();
    tankPlayer.dispose();
    bombStartPlayer.dispose();
    bombBoomPlayer.dispose();
    warShipBoomPlayer.dispose();
    super.dispose();
  }

  _startDroneSound() async {
    await dronePlayer.setVolume(0.25);
    await dronePlayer.setAsset('assets/drone.mp3');
    await dronePlayer.setLoopMode(LoopMode.all);
    dronePlayer.play();
  }

  _prepareOtherSounds() async {
    await tankPlayer.setVolume(0.6);
    await tankPlayer.setAsset('assets/tank.mp3');
    await tankPlayer.setLoopMode(LoopMode.all);
    tankPlayer.play();

    await bombStartPlayer.setVolume(1);
    await bombStartPlayer.setAsset('assets/bombStart.mp3');
    await bombStartPlayer.setLoopMode(LoopMode.off);

    await bombBoomPlayer.setVolume(1);
    await bombBoomPlayer.setAsset('assets/bombBoom.mp3');
    await bombBoomPlayer.setLoopMode(LoopMode.off);

    await warShipBoomPlayer.setVolume(1);
    await warShipBoomPlayer.setAsset('assets/droneBoom.mp3');
    await warShipBoomPlayer.setLoopMode(LoopMode.off);
  }

  _refresh() async {
    if (bombReloadTimer>0) {
      bombReloadTimer+=refreshPeriod/1000;
      if (bombReloadTimer >= bombReloadTime) {
        bombReloadTimer = 0;
      }
    }
    for (int idx=0; idx<bombs.length; idx++) {
      Bomb bomb = bombs[idx];
      bomb.y += bomb.vy*speedUpRate;
      if (bomb.y > fieldSize.height-20) {
        bombs.removeAt(idx);
      } else if (bomb.y < 0) {
        bombs.removeAt(idx);
      }
    }
    for (int idx=0; idx<subs.length; idx++) {
      Sub sub = subs[idx];
      if (sub.isDamaged) {
        sub.boomTimer += refreshPeriod;
        sub.y += sub.vy;
        if (sub.y >= fieldSize.height-20 || sub.boomTimer>1300) {
          subs.removeAt(idx);
          _createSub();
        }
      } else {
        sub.x += sub.vx;
        if (sub.x > fieldSize.width) {
          sub.vx = -sub.vx;
          //subs.removeAt(idx);
          liveCounter++;
        } else {
          if (sub.x < -sub.width) {
            sub.vx = -sub.vx;
            //subs.removeAt(idx);
            liveCounter++;
          } else {
            int chance = rng.nextInt(300);
            if (chance == 250) {
              Bomb b = Bomb();
              b.vy = -3;
              b.y = sub.y; b.x = sub.x;
              bombs.add(b);
            }
          }
        }
      }
    }
    if (warShip.isDamaged) {
      warShip.warShipBoomTimer += refreshPeriod/1000;
      if (warShip.warShipBoomTimer > warShip.warShipMaxBoomTimer) {
        print('go up');
        Navigator.pop(context);
        return;
      }
    } else {
      if (isMoveRight) {
        warShip.x += warShip.vx;
        if (warShip.x > (fieldSize.width-2*warShip.width/3)) {
          warShip.x = fieldSize.width-2*warShip.width/3;
        }
      }
      if (isMoveLeft) {
        warShip.x -= warShip.vx;
        if (warShip.x < (-warShip.width/3)) {
          warShip.x = -warShip.width/3;
        }
      }
    }
    await _checkForBooms();
    if (subs.length < curMaxSubs) {
      _createSub();
      print('after _createSub');
    }
    if (mounted){
      setState((){});
    }
    Future.delayed(Duration(milliseconds: refreshPeriod), _refresh);
  }

  _checkForBooms() async {
    for (var sub in subs) {
      if (sub.isDamaged) {
        continue;
      }
      for (int idx=0; idx < bombs.length; idx++) {
        Bomb bomb = bombs[idx];
        if (bomb.vy < 0) {
          continue;
        }
        double dx=sub.x+sub.width/3-(bomb.x+bomb.width/2);
        if (dx < 0) {
          dx = -dx;
        }
        double dy=bomb.y+bomb.height/2-(sub.y+sub.height/2);
        if (dy < 0) {
          dy = -dy;
        }
        if (dx < sub.width*0.6) {
          double dy2 = bomb.y-sub.y;
          if (dy2<0) {
            dy2 = -dy2;
          }
          if (dy <= sub.height*0.6 || dy2<sub.height*0.6) {
            sub.isDamaged = true;
            sub.boomTimer = 0.001;
            deadCounter ++;
            bombs.removeAt(idx);
            await bombBoomPlayer.seek(Duration.zero);
            bombBoomPlayer.play();
            if (deadCounter % 8 == 0) {
              curMaxSubs++;
            }
          }
        }
      }
    }
    for (var bomb in bombs) {
      if (bomb.vy > 0) {
        continue;
      }
      double dx = (warShip.x+warShip.width/3) - (bomb.x + bomb.width/2);
      double dy = bomb.y - (warShip.y+warShip.height/2);
      double distance = sqrt(dx*dx+dy*dy);
      if (distance < 40) {
        //print('boom! $distance'); Ugly boy
        if (!warShip.isDamaged){
          warShip.isDamaged = true;
          warShip.warShipBoomTimer = 0.001;
          await warShipBoomPlayer.seek(Duration.zero);
          warShipBoomPlayer.play();
        }
      }
    }
  }

  List <Widget> subsW() {
    List <Widget> l = [];
    for (int idx=0; idx<subs.length; idx++){
      Sub sub = subs[idx];
      Widget _img;
      if (sub.isDamaged) {
        double mult = sub.boomTimer/1000;
        //print('mult $mult');
        if (mult < 1) {
          mult = 1 - mult;
        } else if (mult > 1 && mult < 2) {
          mult = mult - 1;
        } else if (mult > 2 && mult < 3) {
          mult = 3 - mult;
        } else {
          mult = 0.3;
        }
        _img = Container(
            width: sub.width, height: sub.height,
            child: Center(child: Image.asset('assets/boom.png', width: sub.width*mult, height: sub.height*mult,))
        );
      } else {
        _img = Image.asset('assets/${sub.name}.png', width: sub.width, height: sub.height,);
        if (sub.vx < 0) {
          _img = Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(3.1415926),
            child: _img,
          );
        }
      }
      l.add(Positioned(
          left: sub.x, top: sub.y,
          child: _img)
      );
    }
    return l;
  }

  List <Widget> bombsW() {
    List <Widget> l = [];
    bombs.forEach((bomb) {
      l.add(Positioned(
          top: bomb.y, left: bomb.x,
          child: Image.asset('assets/torpedo${bomb.vy>0?'Down':'Up'}.png', height: 40,))
      );
    });
    return l;
  }

  _dropBomb(){
    if (bombReloadTimer > 0) {
      return;
    }
    bombReloadTimer = 0.001;
    Bomb bomb = Bomb();
    bomb.x = warShip.x+warShip.width/2-20;
    bomb.y = warShip.y+warShip.height;
    bombs.add(bomb);
    bombStartPlayer.seek(Duration.zero);
    bombStartPlayer.play();
  }

  List <Widget> controls() {
    List <Widget> l = [];
    l.add(Positioned(
      top: fieldSize.height/2-70, left: 0,
      child: GestureDetector(
        onPanEnd: (det){
          isMoveLeft = false;
          isMoveRight = false;
        },
        onTapDown: (det){
          if (isMoveRight) {
            isMoveRight = false;
          }
          isMoveLeft = true;
        },
        onTapUp: (det){
          isMoveLeft = false;
        },
        child: ClipOval(
            child: Container(
              width: 100, height: 100,
              color: Colors.green.withOpacity(0.5),
                child: Center(child: Icon(Icons.arrow_back_ios)))),
      ),
    ));
    l.add(Positioned(
      top: fieldSize.height/2-70, right: 0,
      child: GestureDetector(
        onPanEnd: (det){
          isMoveLeft = false;
          isMoveRight = false;
        },
        onTapDown: (det){
          if (isMoveLeft) {
            isMoveLeft = false;
          }
          isMoveRight = true;
        },
        onTapUp: (det){
          isMoveRight = false;
        },
        child: ClipOval(
            child: Container(
                width: 100, height: 100,
                color: Colors.green.withOpacity(0.5),
                child: const Center(child: Icon(Icons.arrow_forward_ios)))),
      ),
    ));
    l.add(Positioned(
      top: fieldSize.height/2-70+140, right: 0,
      child: GestureDetector(
        onTap: _dropBomb,
        child: ClipOval(
            child: Container(
                width: 100, height: 100,
                color: Colors.green.withOpacity(0.5),
                child: Center(
                    child:
                    bombReloadTimer==0?
                      const Icon(Icons.arrow_drop_down, size: 60,)
                        :
                      Text(bombReloadTimer.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 30),
                      )
                )
            )
        ),
      ),
    ));
    return l;
  }

  bool _isSubAtSuchY(double y) {
    for (var sub in subs) {
      double dy = y-sub.y;
      if (dy<0) {
        dy = -dy;
      }
      if (dy < sub.height) {
        return true;
      }
    }
    return false;
  }

  _createSub() async {
    print('create sub');
    Sub sub = Sub();
    int tankIdx = rng.nextInt(4);
    print('tankIdx $tankIdx');
    if (tankIdx == 0) {
      sub.name = 'tank_bmp';
      sub.vx *= 1.6;
    } else if (tankIdx == 1) {
      sub.name = 'tank_kv2';
      sub.vx *= 0.9;
    } else if (tankIdx == 2) {
      sub.name = 'tank_sau';
      sub.vx *= 0.7;
    } else {
      sub.name = 'tank_t34';
      sub.vx *= 1.2;
    }
    for (int i=0; i<100; i++) {
      sub.y = rng.nextDouble()*(yellowHeight-30)+blueHeight;
      if (!_isSubAtSuchY(sub.y)) {
        break;
      }
    }
    double speedK = (sub.y-blueHeight)/yellowHeight;
    print('source speed ${sub.vx} speedK $speedK sub.y ${sub.y.toStringAsFixed(2)} bH $blueHeight yH $yellowHeight');
    sub.vx = sub.vx*(1 - 1/3*speedK)*speedUpRate;
    print('correct speed to ${sub.vx.toStringAsFixed(2)}');
    if (rng.nextBool()) {
      sub.x = -sub.width;
      if (sub.vx < 0) {
        sub.vx = -sub.vx;
      }
    } else {
      sub.x = fieldSize.width;
      if (sub.vx > 0) {
        sub.vx = -sub.vx;
      }
    }
    subs.add(sub);
    speedUpRate+=0.01;
    print('speedUpRate $speedUpRate');
  }

  Widget droneBoomW(){
    Widget _img;
    double mult = 1 - warShip.warShipBoomTimer/warShip.warShipMaxBoomTimer;
    //print('mult $mult');
    _img = Container(
        width: warShip.width, height: warShip.height,
        child: Center(child: Image.asset('assets/boom.png', width: warShip.width*mult, height: warShip.height*mult,))
    );
    return _img;
  }

  @override
  Widget build(BuildContext context) {
    fieldSize = MediaQuery.of(context).size;
    if (warShip.x == 0) {
      warShip.x = fieldSize.width/2 - warShip.width/2;
    }
    blueHeight = fieldSize.height/2;
    yellowHeight = fieldSize.height-blueHeight;
    return Material(
      child: SizedBox(
        width: fieldSize.width, height: fieldSize.height,
        child: Stack(
          children: [
            Positioned(
              top: 0, left: 0,
              child: Container(
                width: fieldSize.width,
                height: blueHeight,
                color: Colors.lightBlueAccent[100],
              ),
            ),
            Positioned(
              top: blueHeight+1, left: 0,
              child: Container(
                width: fieldSize.width,
                height: yellowHeight,
                color: Colors.yellow[300],
              ),
            ),
            Positioned(
              right: 10, top: 50,
                child: Text('$deadCounter',
                  style: const TextStyle(fontSize: 40, color: Colors.redAccent),
                )
            ),
            Positioned(
              top: warShip.y, left: warShip.x,
              child:
              warShip.isDamaged?
                droneBoomW()
              :
                Image.asset('assets/drone.png', width: warShip.width, height: warShip.height,),
            ),
            bombReloadTimer == 0?
            warShip.isDamaged?
            const SizedBox()
              :
            Positioned(
              top: warShip.y+20, left: warShip.x+warShip.width/2-20,
              child: Image.asset('assets/torpedoDown.png', width: 40, height: 90,),
            )
                :
            const SizedBox(),
            ...subsW(),
            ...bombsW(),
            ...controls(),
          ],
        ),
      ),
    );
  }
}
