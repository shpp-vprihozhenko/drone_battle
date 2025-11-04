import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'globals.dart';
import 'painter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
//import 'package:just_audio/just_audio.dart';
import 'package:audioplayers/audioplayers.dart';

/*

тип боеприпаса - для танков, для БМП, фугасы...
скорость танков зависит от размера экрана! + портрет/ландскейп
если танк "заметил" (10 сек) - то стреляет, щит потих. разряж., за 30 сек.

 */

class BattleField extends StatefulWidget {
  final String imgName;
  final double scale;

  const BattleField(this.imgName, {super.key, required this.scale});

  @override
  _BattleFieldState createState() => _BattleFieldState();
}

class _BattleFieldState extends State<BattleField> {
  ui.Image? _image;
  Size _imageSize = const Size(0,0);
  Offset _offset = const Offset(0, 0);
  double _scale = 1, baseScale = 16;
  Size _canvasSize = const Size(0,0);
  List <Tank> tanks = [];
  List <Bomb> bombs = [];
  double bombReloadTime = 0, accumulatorLife = 0;
  int liveTanks = glTanksPerMap;
  List <Target> killedTanks = [];

  var rng = Random();

  final dronePlayer = AudioPlayer();
  final tankPlayer = AudioPlayer();
  final bombStartPlayer = AudioPlayer();
  final bombBoomPlayer = AudioPlayer();
  final warShipBoomPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _loadImages();
    _refresh();
    _startDroneSound();
    _prepareOtherSounds();
    context.read<TankCubit>().reset();
    glPassedFor = 0;
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
    printD('_startDroneSound');
    await dronePlayer.setSource(AssetSource('sounds/drone.wav'));
    printD('_startDroneSound 1');
    await dronePlayer.setVolume(0.15);

    //await dronePlayer.setLoopMode(LoopMode.all);
    await dronePlayer.setReleaseMode(ReleaseMode.loop);
    dronePlayer.seek(Duration.zero);
    printD('_startDroneSound 2');
    dronePlayer.play(AssetSource('sounds/drone.wav'));
    printD('_startDroneSound 3');
  }

  _prepareOtherSounds() async {
    await tankPlayer.setVolume(0.6);
    await tankPlayer.setSource(AssetSource('sounds/tank.mp3'));
    await tankPlayer.setReleaseMode(ReleaseMode.loop);

    await bombStartPlayer.setVolume(1);
    await bombStartPlayer.setSource(AssetSource('sounds/bombStart.mp3'));
    await bombStartPlayer.setReleaseMode(ReleaseMode.release);

    await bombBoomPlayer.setVolume(1);
    await bombBoomPlayer.setSource(AssetSource('sounds/bombBoom.mp3'));
    await bombBoomPlayer.setReleaseMode(ReleaseMode.release);

    await warShipBoomPlayer.setVolume(1);
    await warShipBoomPlayer.setSource(AssetSource('sounds/droneBoom.mp3'));
    await warShipBoomPlayer.setReleaseMode(ReleaseMode.release);
  }

  _countKilledTargets(TankModel model){
    int counter = 0;
    for (var kt in killedTanks) {
      if (kt.model == model) {
        counter++;
      }
    }
    return counter;
  }

  _refresh(){
    accumulatorLife += glRefreshPeriodMs/1000;
    glPassedFor = accumulatorLife;
    if (glAccumulatorLifeSeconds - accumulatorLife <= 0) {
      Navigator.pop(context, 'Drone battery is empty');
      return;
    }
    if (glDroneLife == 0) {
      Navigator.pop(context, 'Drone is broken');
      return;
    }
    if (bombReloadTime > 0) {
      bombReloadTime -= glRefreshPeriodMs/1000;
      if (bombReloadTime < 0) {
        bombReloadTime = 0;
      }
    }
    glDroneDX = -glDroneDX;
    bool isTankOnCanvas = false;
    int killedTanksTotal = 0;
    for (int idx=0; idx<tanks.length; idx++) {
      Tank tank = tanks[idx];
      if (tank.isDamaged) {
        killedTanksTotal++;
        continue;
      } else {
        if (isBombBoomNearly(tank)) { //
          tank.lifeCounter --;
          printD('lifeCounter --');
          if (tank.lifeCounter == 0) {
            tank.isDamaged = true;
            killedTanks.add(Target(tank.model, 1));
            tank.speed = 0;
            context.read<TankCubit>().registryTankKill();
            continue;
          } else {
            tank.speed = tank.speed/2;
          }
        }
      }
      if (tank.isOnCanvas) {
        isTankOnCanvas = true;
      }
      if (!tank.isRotated) {
        double dx = tank.speed * cos(tank.direction*pi/180);
        tank.x = tank.x + dx;
        if (tank.x < 0) {
          tank.direction = rng.nextInt(360);
          tank.x = 0;
          _updateTankImgData(tank);
          continue;
        } else if (tank.x > _image!.width) {
          tank.direction = rng.nextInt(360);
          tank.x = _image!.width.toDouble();
          _updateTankImgData(tank);
          continue;
        }
        double dy = tank.speed * sin(tank.direction*pi/180);
        tank.y = tank.y + dy;
        if (tank.y < 0) {
          tank.direction = rng.nextInt(360);
          tank.y = 0;
          _updateTankImgData(tank);
          continue;
        } else if (tank.y > _image!.height) {
          tank.direction = rng.nextInt(360);
          tank.y = _image!.height.toDouble();
          _updateTankImgData(tank);
          continue;
        }
      }
      if (isTankNearly(tank)) {
        tank.direction += 3; //5;
        tank.isRotated = true;
        _updateTankImgData(tank);
      } else {
        if (tank.isRotated) {
          tank.isRotated = false;
        }
      }
    }
    if (killedTanksTotal >= glTanksToKill) {
      if (glCurrentMission!.targets.isNotEmpty) {
        bool isAllTargetsKilled = true;
        for (var target in glCurrentMission!.targets) {
          int killedTargets = _countKilledTargets(target.model);
          if (killedTargets < target.quantity) {
            isAllTargetsKilled = false;
            break;
          }
        }
        if (isAllTargetsKilled) {
          Navigator.pop(context, 'win');
          return;
        }
      } else {
        Navigator.pop(context, 'win');
        return;
      }
    }
    if (!isTankOnCanvas) {
      glDroneLife += 0.1;
      if (glDroneLife > 100) {
        glDroneLife = 100;
      }
    }
    for (int idx=0; idx<bombs.length; idx++) {
      Bomb bomb = bombs[idx];
      bomb.height -= bomb.speed;
      if (bomb.height <= 50) {
        if (bomb.height > 0) {
          printD("\nBOOM\n");
          bombBoomPlayer.seek(Duration.zero);
          bombBoomPlayer.play(AssetSource('sounds/bombBoom.mp3'));
        }
        bomb.height = 0;
        bomb.boomTimer += glRefreshPeriodMs/1000;
        if (bomb.boomTimer > glBombBoomTime) {
          printD('remove bomb $idx');
          bombs.removeAt(idx);
        }
      }
    }
    setState(() {});
    Future.delayed(const Duration(milliseconds: glRefreshPeriodMs), _refresh);
  }

  isBombBoomNearly(Tank tank) {
    Offset tankOffset = Offset(tank.x*_scale, tank.y*_scale) - Offset(10*cos(tank.direction*kpi), 10*sin(tank.direction*kpi));
    // + Offset(tank.uiImg!.width/2-25, tank.uiImg!.height/2-8);
    for (var bomb in bombs) {
      if (bomb.boomTimer == 0 || bomb.boomTimer > 0.5) {
        continue;
      }
      if (tank.lastBomb == bomb) {
        continue;
      }
      double dx = tankOffset.dx - bomb.targetPoint.dx+8;
      double dy = tankOffset.dy - bomb.targetPoint.dy+33;
      double distance = sqrt(dx*dx + dy*dy);
      if (distance < 50) {
        tank.lastBomb = bomb;
        return true;
      }
    }
    return false;
  }

  bool isTankNearly(Tank tTank) {
    for (var tank in tanks) {
      if (tTank.id == tank.id) {
        continue;
      }

      double dx = tank.x - (tTank.x+tTank.forehead.dx*cos(tank.direction*kpi));
      double dy = tank.y - (tTank.y+tTank.forehead.dy*sin(tank.direction*kpi));
      double distance = sqrt(dx*dx + dy*dy);
      double criticalDistance = 20; //tTank.height>tTank.width? tTank.height : tTank.width;
      if (distance < criticalDistance) {
        //printD('tTank $tTank \nnearly tank $tank');
        //printD('dx ${dx.toInt()} dy ${dy.toInt()} distance ${distance.toInt()} tTank.height ${tTank.height.toInt()}');
        return true;
      }
    }
    return false;
  }

  _updateTankImgData(Tank tank) async {
    tank.uiImg = await getRotatedTank(tank.direction, tank.pImg);
    tank.width = tank.uiImg!.width.toDouble();
    tank.height = tank.uiImg!.height.toDouble();
    tank.forehead = Offset(tank.width/2, tank.height/2)+Offset(tank.foreheadLength * cos(tank.direction*kpi),
        tank.foreheadLength * sin(tank.direction*kpi)
    );
  }

  _loadImages() async {
    if (uiBaggi == null) {
      var value = await loadImage('assets/baggi.png');
      uiBaggi = value["ui"];
      printD('got uiBaggi $uiBaggi');
      pBaggi = value["p"];
      printD('got pBaggi ${pBaggi!.width}/${pBaggi!.height}');

      value = await loadImage('assets/bmp.png');
      uiBmp = value["ui"];
      printD('got uiBmp $uiBmp');
      pBmp = value["p"];
      printD('got pBmp ${pBaggi!.width}/${pBaggi!.height}');

      value = await loadImage('assets/mamonth.png');
      uiMamonth = value["ui"];
      printD('got uiMamonth $uiMamonth');
      pMamonth = value["p"];
      printD('got pMamonth $pMamonth');

      value = await loadImage('assets/mlrs.png');
      uiMlrs = value["ui"];
      printD('got uiMlrs $uiMlrs');
      pMlrs = value["p"];
      printD('got pMlrs $pMlrs');

      value = await loadImage('assets/sau.png');
      uiSau = value["ui"];
      printD('got uiSau $uiSau');
      pSau = value["p"];
      printD('got pSau $pSau');

      value = await loadImage('assets/tank.png');
      uiTank1 = value["ui"];
      printD('got uiTank1 $uiTank1');
      pTank1 = value["p"];
      printD('got pTank1 $pTank1');

      value = await loadImage('assets/tank2.png');
      uiTank2 = value["ui"];
      printD('got uiTank2 $uiTank2');
      pTank2 = value["p"];
      printD('got pTank2 $pTank2');

      value = await loadImage('assets/boom.png');
      uiBoom = value["ui"];
      printD('got uiBoom $uiBoom');

      value = await loadImage('assets/bomb.png');
      uiBomb = value["ui"];
      printD('got uiBomb $uiBomb');

      value = await loadImage('assets/bomb2.png');
      uiBomb2 = value["ui"];
      printD('got uiBomb2 $uiBomb2');

      value = await loadImage(widget.imgName);
      uiMap = value["ui"];
      printD('got uiMap $uiMap');
    }
    _image = uiMap;
    _addTanks();
    setState(() {});
  }

  _addTanks() async {
    Tank t = Tank(0,0,0,0);
    double maxX = _image!.width-t.width,  maxY = _image!.height-t.height;
    for (int i=0; i<glTanksPerMap; i++) {
      Tank tank = Tank(rng.nextDouble()*maxX, rng.nextDouble()*maxY, rng.nextInt(360), rng.nextDouble()*glMaxTankSpeed+glMinTankSpeed);
      tank.id = i;
      tank.pImg = pTank1; tank.model = TankModel.type1;
      int tankType = rng.nextInt(7);
      printD('got tankType $tankType for $i');
      if (tankType == 1) {
        tank.pImg = pTank2; tank.model = TankModel.type2;
      } else if (tankType == 2) {
        tank.pImg = pBaggi; tank.model = TankModel.baggie;
        tank.speed *= 2;
      } else if (tankType == 3) {
        tank.pImg = pBmp; tank.model = TankModel.bmp;
        tank.speed *= 1.5;
      } else if (tankType == 4) {
        tank.pImg = pMamonth; tank.model = TankModel.mammoth;
        tank.speed *= 0.7;
        tank.lifeCounter = 2;
      } else if (tankType == 5) {
        tank.pImg = pMlrs; tank.model = TankModel.mlrs;
        tank.speed *= 0.6;
      } else if (tankType == 6) {
        tank.pImg = pSau; tank.model = TankModel.sau;
        tank.speed *= 0.5;
      }
      printD('add ${tank.model.name}');
      await _updateTankImgData(tank);
      tanks.add(tank);
    }
    printD('tanks added $tanks');
  }

  void _centerAndScaleImage() {
    _imageSize = Size(_image!.width.toDouble(), _image!.height.toDouble(),);
    _scale = min(
      _canvasSize.width / _imageSize.width,
      _canvasSize.height / _imageSize.height,
    );

    _scale = _scale * baseScale;

    Size fitted = Size(_imageSize.width * _scale, _imageSize.height * _scale,);

    _offset = Offset((_canvasSize.width-fitted.width)/2, (_canvasSize.height-fitted.height)/2); //_canvasSize - fitted;
    // Centers the image
    if (kDebugMode) {
      _offset = const Offset(1, 1);
    }
    printD('_centerAndScaleImage _imageSize $_imageSize _scale $_scale _canvasSize $_canvasSize fitted $fitted delta $_offset');
    printD(_scale);
  }

  _dropBomb({String bombType = 'normal'}) async {
    if (bombReloadTime > 0) {
      return;
    }
    if (glBombsQuantity == 0) {
      Navigator.pop(context, 'Bombs is absent');
    }
    glBaseBombHeight = _canvasSize.height*2/3-glStartBombHeightShift;
    Bomb bomb = Bomb(glMapDronePos, glBaseBombHeight, glBombSize);
    if (bombType == 'quick') {
      if (glExtraSpeedBombsQuantity == 0) {
        return;
      }
      glExtraSpeedBombsQuantity--;
      bomb.speed = 2.5*glBaseBombSpeed;
      bomb.isExtra = true;
    } else {
      glBombsQuantity--;
    }
    bombs.add(bomb);
    printD('add $bomb with _offset $_offset');
    bombReloadTime = glBombReloadTime;
    context.read<TankCubit>().registryDropBomb();
    setState(() {});
    bombStartPlayer.seek(Duration.zero);
    bombStartPlayer.play(AssetSource('sounds/bombStart.mp3'));
  }

  void _onPanUpdate(DragUpdateDetails details) {
    //printD('_onPanUpdate $details');
    _offset += details.delta;
    //Offset pos = (context.findRenderObject() as RenderBox).globalToLocal(details.globalPosition);
    setState((){});// 414.0, 660.0
    //printD('target $glTargetPoint offset $_offset _scale $_scale');
  }

  @override
  Widget build(BuildContext ctx) {
    if (_image == null) {
      return const Center(child: CircularProgressIndicator());
    }
    Size size = MediaQuery.of(ctx).size;

    gl2dDronePos = Offset(size.width/2, 75);

    double accumulatorLifeRest = glAccumulatorLifeSeconds - accumulatorLife;
    double accumulatorLifePercent = accumulatorLifeRest/glAccumulatorLifeSeconds*100;

    return LayoutBuilder(builder: (ctx, constraints) {
      _canvasSize = constraints.biggest;
      if (_canvasSize.width == double.infinity) {
        _canvasSize=Size(size.width, _canvasSize.height) ;
      }
      if (_canvasSize.height == double.infinity) {
        _canvasSize=Size(_canvasSize.width, size.height) ;
      }
      if (_offset.dx == 0) {
        _centerAndScaleImage();
      }
      return Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              Expanded(
                child: ClipRect(
                  child: GestureDetector(
                    onPanUpdate: _onPanUpdate,
                    child: CustomPaint(
                      foregroundPainter: ZoomableImagePainter(_image!, _offset, _scale, tanks, bombs),
                      child: Container(color: Colors.blueAccent),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: -20, left: glDroneDX,
            child: SizedBox(
              width: size.width,
                child: Image.asset('assets/drone1.png')
            ),
          ),
          Positioned(
            top: 10, left: (size.width-glDroneLifeWidth)/2, //
            child: Container(
              width: glDroneLifeWidth, height: 8,
              color: Colors.black,
            ),
          ),
          Positioned(
            top: 10, left: (size.width-glDroneLifeWidth)/2, //
            child: Container(
              width: glDroneLifeWidth*glDroneLife/100, height: 8,
              color:
              glDroneLife > 50?
                Colors.greenAccent
                  :
              glDroneLife>25?
                Colors.yellow
                  :
                Colors.red
              ,
            ),
          ),
          Positioned(
            right: 10, top: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  accumulatorLifePercent>50?
                    Icons.battery_full
                      :
                  accumulatorLifePercent>25?
                    Icons.battery_4_bar
                      :
                    Icons.battery_1_bar
                  , color:
                accumulatorLifePercent>50?
                  Colors.green
                    :
                accumulatorLifePercent>25?
                  Colors.yellow
                    :
                  Colors.red,
                ),
                Text(accumulatorLifeRest.toStringAsFixed(0))
              ],
            ),
          ),
          bombReloadTime > 0?
            const SizedBox()
          :
            Positioned(
              top: glStartBombHeightShift, left: glDroneDX,
              child: SizedBox(
                  width: size.width,
                  child: Image.asset('assets/bomb.png', height: glBombSize,)
              ),
            ),
          Positioned(
            bottom: 40, left: 40, //size.width/2-glBombBtnSize/2
            child: ClipOval(
              child: GestureDetector(
                onTap: (){
                  _dropBomb(bombType: 'quick');
                },
                child: Container(
                  color: Colors.blue.withOpacity(0.3),
                  width: glBombBtnSize, height: glBombBtnSize,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Image.asset('assets/bomb2.png',),
                          Positioned(
                            top: 35, left: 25,
                            child: Text(glExtraSpeedBombsQuantity.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 22),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40, right: 40, //size.width/2-glBombBtnSize/2
            child: ClipOval(
              child: GestureDetector(
                onTap: _dropBomb,
                child: Container(
                  color: Colors.blue.withOpacity(0.3),
                  width: glBombBtnSize, height: glBombBtnSize,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Image.asset('assets/bomb.png',),
                          Positioned(
                            top: 35, left: 25,
                            child: Text(glBombsQuantity.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 22),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

