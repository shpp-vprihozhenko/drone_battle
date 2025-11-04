import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as imgLib;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum TankModel {
  baggie,
  bmp,
  mammoth,
  mlrs,
  sau,
  type1,
  type2
}

int deadCounter=0, liveCounter=0;
String nodeEndPoint = 'http://173.212.250.234:6641';
List <UserResult> url = [];

int glTanksPerMap = 100, glTanksToKill = 1, glBombsQuantity=999, glAccumulatorLifeTime=5;
const glRefreshPeriodMs = 24;
const glMaxTankSpeed = glRefreshPeriodMs / 100 * 0.75;
const glMinTankSpeed = 0.15;
const double glBombSize = 60;
const double glStartBombHeightShift = 75;
const double glBombReloadTime = 3.5;
const double glBombBoomTime = 1.5;
double glBaseBombHeight = 0;
double glBombSpeed = 2, glBaseBombSpeed = 2;
bool isU24visited = false;
int glExtraSpeedBombsQuantity = 0;

double glDroneDX = 0.6;
double glBombBtnSize = 100;
Offset glTargetPoint = const Offset(0, 0);
double glDroneLifeWidth = 200;
Offset gl2dDronePos = const Offset(0, 0);
Offset glMapDronePos = const Offset(0, 0);
double glDroneLife = 100, glAccumulatorLifeSeconds = 100;

Mission? glCurrentMission;

const glDroneRadarRadius = 2000;

const kpi = 3.1415926/180;

class Missile {
  double x1=0, y1=0, z1=0, x2=0, y2=0, z2=0;
  double targetX=0, targetY=0, targetZ=0;

  @override
  String toString() {
    return 'missile $x1/$y1/$z1 - $x2/$y2/$z2 target $targetX/$targetY/$targetZ';
  }
}

class Bomb {
  Offset targetPoint = const Offset(0, 0);
  double height = 0;
  double size = 0;
  double boomTimer = 0;
  double speed = glBaseBombSpeed;
  bool isExtra = false;

  Bomb(this.targetPoint, this.height, this.size);

  @override
  String toString() {
    return 'bomb to $targetPoint height $height';
  }
}

class Tank {
  int id=-1;
  int direction=0;
  double x=0, y=0, width=70, height=35, foreheadLength=40;
  bool isDamaged = false;
  double speed=0;
  double lastCriticalDist=0;
  bool isRotated = false;
  ui.Image? uiImg;
  imgLib.Image? pImg;
  Offset forehead = const Offset(0, 0);
  bool isOnCanvas = false;
  int gunStage = 0;
  Offset missilePos = const Offset(0, 0);
  Offset canvasPos = const Offset(0, 0);
  Offset mapPos = const Offset(0, 0);
  TankModel model = TankModel.type1;
  int lifeCounter = 1;
  Bomb? lastBomb;

  Tank(this.x, this.y, this.direction, this.speed);

  @override
  String toString() {
    return 'id $id x ${x.toInt()} y${y.toInt()} dir $direction isDam $isDamaged';
  }
}

imgLib.Image? pTank1;
imgLib.Image? pTank2;
imgLib.Image? pBmp;
imgLib.Image? pBaggi;
imgLib.Image? pMamonth;
imgLib.Image? pMlrs;
imgLib.Image? pSau;

ui.Image? uiTank1;
ui.Image? uiTank2;
ui.Image? uiBmp;
ui.Image? uiBaggi;
ui.Image? uiMamonth;
ui.Image? uiMlrs;
ui.Image? uiSau;

ui.Image? uiBomb, uiBomb2;
ui.Image? uiBoom;
imgLib.Image? pBomb;
imgLib.Image? pBoom;

ui.Image? uiMap;

imgLib.PngEncoder pngEncoder = imgLib.PngEncoder(level: 0, filter: 0);

loadUiImage(Uint8List list) async {
  /*
  if (assetPath.contains('bomb.png')) {
    pBomb = imgLib.decodeImage(list.toList());
    printD('got pBomb $pBomb');
  } else if (assetPath.contains('boom.png')) {
    pBoom = imgLib.decodeImage(list.toList());
    printD('got pBoom $pBoom');
  }

   */
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(list, completer.complete);
  return completer.future;
}

loadImage(String imgPath) async {
  final data = await rootBundle.load(imgPath);
  final list = Uint8List.view(data.buffer);
  var result = {};
  result["p"] = imgLib.decodeImage(list.toList());
  result["ui"] = await loadUiImage(list);
  return result;
}

Future<ui.Image> getFromUint8List(Uint8List bytes) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(bytes, completer.complete);
  return completer.future;
}

Future<ui.Image> getRotatedTank(angle, pImg) async {
  imgLib.Image ilTank = imgLib.copyRotate(pImg, angle);
  Uint8List imgBytes = Uint8List.fromList(pngEncoder.encodeImage(ilTank));
  ui.Image uiImg = await getFromUint8List(imgBytes);
  return uiImg;
}

Future<ui.Image> getResizedBomb(double percent) async {
  imgLib.Image ilBomb = imgLib.copyResize(pBomb!, width: pBomb!.width*percent.toInt());
  Uint8List imgBytes = Uint8List.fromList(pngEncoder.encodeImage(ilBomb));
  ui.Image uiImg = await getFromUint8List(imgBytes);
  return uiImg;
}

printD(text){
  if (kDebugMode) {
    print(text);
  }
}

class CommonData {
  int killedCounter = 0;
  int restOfTanks = 100;
  int bombsQuantity = 0;

  CommonData(this.killedCounter, this.restOfTanks, this.bombsQuantity);

  CommonData.clone(CommonData existing): this(existing.killedCounter, existing.restOfTanks, existing.bombsQuantity);

  @override
  String toString() {
    return '$killedCounter/$restOfTanks';
  }
}

class TankCubit extends Cubit<CommonData> {
  TankCubit() : super(CommonData(0,0,0));

  void reset() {
    CommonData newState = CommonData(0,glTanksToKill,glBombsQuantity);
    emit(newState);
  }

  void registryDropBomb() {
    CommonData newState = CommonData.clone(state);
    newState.bombsQuantity = glBombsQuantity;
    emit(newState);
  }

  void registryTankKill() {
    CommonData newState = CommonData.clone(state);
    newState.killedCounter = state.killedCounter + 1;
    emit(newState);
  }
}

Future <void> showAlertPage(context, String msg) async {
  await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(msg),
        );
      }
  );
}

Future <void> showResultPage(context, String msg1, String msg2, bool isWin) async {
  Size size = MediaQuery.of(context).size;
  await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Container(
            width: size.width*0.75, height: 200,
            color: Colors.green.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(msg1,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                      color: isWin? Colors.purple:Colors.red),
                  ),
                  const SizedBox(height: 12,),
                  msg2==''? const SizedBox() : Text(msg2, style: const TextStyle(fontSize: 24), textAlign: TextAlign.center,),
                  const SizedBox(height: 12,),
                  ElevatedButton(onPressed: (){
                    Navigator.pop(context);
                  }, child: const Text('OK'))
                ],
              )
            )
          ),
        );
      }
  );
}

class Mission {
  int bombsQuantity, tanksPerMap, tanksToHit, accumulatorLifeMin;
  String missionName;
  List <Target> targets = [];
  int missionNumber = 0;

  Mission(this.missionName,
      {required this.bombsQuantity, required this.tanksPerMap, required this.tanksToHit,
        required this.accumulatorLifeMin, tTargets}){
    if (tTargets  != null) {
      targets = tTargets;
      tanksToHit = 0;
      for (var target in targets) {
        tanksToHit += target.quantity;
      }
    }
  }
}

class Target {
  TankModel model;
  int quantity;
  
  Target(this.model, this.quantity);
}

List <Mission> missions = [
  Mission('Bahmut',  bombsQuantity: 10, tanksPerMap: 10, tanksToHit: 3, accumulatorLifeMin: 3),
  Mission('Soledar', bombsQuantity: 10, tanksPerMap: 10, tanksToHit: 4, accumulatorLifeMin: 3),
  Mission('Sloviansk', bombsQuantity: 12, tanksPerMap: 15, tanksToHit: 5, accumulatorLifeMin: 5),
  Mission('Bashtanka', bombsQuantity: 20, tanksPerMap: 20, tanksToHit: 5, accumulatorLifeMin: 5),
  Mission('Bilogorivka', bombsQuantity: 5, tanksPerMap: 2, tanksToHit: 2, accumulatorLifeMin: 2),
  Mission('Kupiansk',  bombsQuantity: 1, tanksPerMap: 1, tanksToHit: 1, accumulatorLifeMin: 1),
  Mission('Izium', bombsQuantity: 20, tanksPerMap: 10, tanksToHit: 10, accumulatorLifeMin: 5),
  Mission('Balakleia', bombsQuantity: 10, tanksPerMap: 10, tanksToHit: 3, accumulatorLifeMin: 3),
  Mission('Irpen', bombsQuantity: 30, tanksPerMap: 20, tanksToHit: 20, accumulatorLifeMin: 6),
  Mission('Snigurivka', bombsQuantity: 3, tanksPerMap: 30, tanksToHit: 1, accumulatorLifeMin: 3,
    tTargets: [Target(TankModel.sau, 1)]),
  Mission('Sviatohirsk', bombsQuantity: 3, tanksPerMap: 30, tanksToHit: 1, accumulatorLifeMin: 3,
      tTargets: [Target(TankModel.mammoth, 1)]),
  Mission('Lyman', bombsQuantity: 3, tanksPerMap: 30, tanksToHit: 1, accumulatorLifeMin: 3,
      tTargets: [Target(TankModel.mlrs, 1)]),
  Mission('Lysychansk', bombsQuantity: 3, tanksPerMap: 30, tanksToHit: 1, accumulatorLifeMin: 3,
      tTargets: [Target(TankModel.type1, 1)]),
  Mission('Severodonetsk', bombsQuantity: 3, tanksPerMap: 30, tanksToHit: 1, accumulatorLifeMin: 3,
      tTargets: [Target(TankModel.type2, 1)]),
  Mission('Svatovo', bombsQuantity: 3, tanksPerMap: 30, tanksToHit: 1, accumulatorLifeMin: 3,
      tTargets: [Target(TankModel.bmp, 1)]),
  Mission('Kreminna', bombsQuantity: 5, tanksPerMap: 30, tanksToHit: 1, accumulatorLifeMin: 3,
      tTargets: [Target(TankModel.baggie, 1)]),
  Mission('Novoselivka', bombsQuantity: 10, tanksPerMap: 20, tanksToHit: 2, accumulatorLifeMin: 3,
      tTargets: [Target(TankModel.type1, 1), Target(TankModel.type2, 1)]),
  Mission('Schastia', bombsQuantity: 10, tanksPerMap: 20, tanksToHit: 3, accumulatorLifeMin: 3,
    tTargets: [Target(TankModel.sau, 1), Target(TankModel.mlrs, 1), Target(TankModel.bmp, 1), ]),
  Mission('Mariupol',  bombsQuantity: 60, tanksPerMap: 30, tanksToHit: 20, accumulatorLifeMin: 10),
  Mission('Kherson', bombsQuantity: 80, tanksPerMap: 30, tanksToHit: 25, accumulatorLifeMin: 8),
  Mission('Chornobaivka', bombsQuantity: 100, tanksPerMap: 30, tanksToHit: 30, accumulatorLifeMin: 10),
];

class UserResult {
  String name = '';
  int score = 0;
}

Future <String> addBestResult (context, String name, int score) async {
  print('addBestResult $name $score');
  var resp = await http.post(
    Uri.parse('$nodeEndPoint/addBestResult'),
    headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8',},
    body: jsonEncode(
        <String, dynamic>{
          'name': name,
          'score': score,
        }
    ),
  );
  if (resp.body == null || resp.body.substring(0,2) != 'ok') {
    showAlertPage(context, 'Error. Try later\n${resp.body}');
    return '';
  }
  return 'ok';
}

getBestResults (context, {String name = ''}) async {
  print('getBestResults');
  var resp = await http.post(
    Uri.parse('$nodeEndPoint/getBestResult'),
    headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8',},
    body: jsonEncode(
        <String, dynamic>{
          'name': name,
        }
    ),
  );
  if (resp.statusCode != 200 || resp.body == null) {
    showAlertPage(context, 'Error. Try later\n${resp.body}');
    return null;
  }
  //print('got ${resp.body}');
  return jsonDecode(resp.body);
}

class MissionResult {
  String missionName='';
  int missionIdx=-1;
  double bestTime=0;

  @override
  String toString() {
    return '$missionName idx $missionIdx best $bestTime';
  }
}

List <MissionResult> missionResultList = [];
double glPassedFor = 0;

glSaveMRL() async {
  var mrvl = [];
  missionResultList.forEach((mr) {
    var mrv = {};
    mrv["missionName"] = mr.missionName;
    mrv["missionIdx"] = mr.missionIdx;
    mrv["bestTime"] = mr.bestTime;
    mrvl.add(mrv);
  });
  String mrs = jsonEncode(mrvl);
  printD('missionResultList encoded to $mrs');
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('missionResultList', mrs);
  printD('missionResultList saved');
}

Future <void> glRestoreMRL() async {
  final prefs = await SharedPreferences.getInstance();
  String? s = prefs.getString('missionResultList');
  if (s == null) {
    printD('no saved data');
    return;
  }
  var mrvl = jsonDecode(s);
  printD('mrvl $mrvl');

  missionResultList = [];
  mrvl.forEach((mrv){
    MissionResult mr = MissionResult();
    mr.missionName = mrv["missionName"];
    mr.missionIdx = mrv["missionIdx"];
    mr.bestTime = mrv["bestTime"];
    missionResultList.add(mr);
  });
  printD('missionResultList restored $missionResultList');
}


