import 'package:flutter/material.dart';
import 'globals.dart';

Mission m = Mission('Snigurivka', bombsQuantity: 3, tanksPerMap: 30, tanksToHit: 1, accumulatorLifeMin: 3,
//    tTargets: [Target(TankModel.sau, 1)]
);

void main() {
  runApp(MediaQuery(
      data: const MediaQueryData(),
      child: MaterialApp(home: MissionDescription(mission: m,))
  ));
}

class MissionDescription extends StatelessWidget {
  final Mission mission;

  const MissionDescription({Key? key, required this.mission}) : super(key: key);

  Widget possibleTargetsW(){
    printD('mission.targets ${mission.targets}');
    if (mission.targets.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/tank.png', height: 50, width: 100,),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(' - tank Type1', textScaleFactor: 1.5,),
                  Text('middle speed, armored', textScaleFactor: 1,),
                ],
              ),
            ],
          ),//type1
          const SizedBox(height: 12,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/tank2.png', height: 50, width: 100,),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(' - tank Type2', textScaleFactor: 1.5,),
                  const Text('enlarged, middle speed', textScaleFactor: 1,),
                ],
              ),
            ],
          ),//type2
          const SizedBox(height: 12,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/bmp.png', height: 50, width: 100,),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(' - fighting vehicle', textScaleFactor: 1.5,),
                  Text('long base, speedy', textScaleFactor: 1,),
                ],
              ),
            ],
          ),//bmp
          const SizedBox(height: 12,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/baggi.png', height: 50, width: 100,),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(' - commander vehicle', textScaleFactor: 1.5,),
                  Text('light weight, fast', textScaleFactor: 1,),
                ],
              ),
            ],
          ),//baggi
          const SizedBox(height: 12,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/mamonth.png', height: 50, width: 100,),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(' - mammoth tank', textScaleFactor: 1.5,),
                  Text('good armored, slowly', textScaleFactor: 1, textAlign: TextAlign.center,),
                  Text('double hit required', textScaleFactor: 1, textAlign: TextAlign.center,),
                ],
              ),
            ],
          ),// mammoth
          const SizedBox(height: 12,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/mlrs.png', height: 50, width: 100,),
              const SizedBox(width: 10,),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(' - MLRS unit', textScaleFactor: 1.5,),
                  Text('good slowly target', textScaleFactor: 1),
                ],
              ),
            ],
          ),//mlrs
          const SizedBox(height: 12,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/sau.png', height: 50, width: 100,),
              Column(
                children: const [
                  Text(' - artillery unit', textScaleFactor: 1.5,),
                  Text('very slowly target', textScaleFactor: 1,),
                ],
              ),
            ],
          ),//sau
        ],
      );
    }
    List <Widget> l = [];
    for (var target in mission.targets) {
      if (target.model == TankModel.type1) {
        l.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/tank.png', height: 50, width: 100,),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(' - tank Type1', textScaleFactor: 1.5,),
                  Text('middle speed, armored', textScaleFactor: 1,),
                ],
              ),
            ],
          ),//type1
        );
      } else if (target.model == TankModel.type2) {
        l.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/tank2.png', height: 50, width: 100,),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(' - tank Type2', textScaleFactor: 1.5,),
                  const Text('enlarged, middle speed', textScaleFactor: 1,),
                ],
              ),
            ],
          ),//type2
        );
      } else if (target.model == TankModel.bmp) {
        l.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/bmp.png', height: 50, width: 100,),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(' - fighting vehicle', textScaleFactor: 1.5,),
                  Text('long base, speedy', textScaleFactor: 1,),
                ],
              ),
            ],
          ),//bmp
        );
      } else if (target.model == TankModel.baggie) {
        l.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/baggi.png', height: 50, width: 100,),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(' - commander vehicle', textScaleFactor: 1.5,),
                  Text('light weight, fast', textScaleFactor: 1,),
                ],
              ),
            ],
          ),//baggi
        );
      } else if (target.model == TankModel.mammoth) {
        l.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/mamonth.png', height: 50, width: 100,),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(' - mammoth tank', textScaleFactor: 1.5,),
                  Text('good armored, slowly', textScaleFactor: 1, textAlign: TextAlign.center,),
                  Text('double hit required', textScaleFactor: 1, textAlign: TextAlign.center,),
                ],
              ),
            ],
          ),// mammoth
        );
      } else if (target.model == TankModel.mlrs) {
        l.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/mlrs.png', height: 50, width: 100,),
              const SizedBox(width: 10,),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(' - MLRS unit', textScaleFactor: 1.5,),
                  Text('good slowly target', textScaleFactor: 1),
                ],
              ),
            ],
          ),//mlrs
        );
      } else if (target.model == TankModel.sau) {
        l.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/sau.png', height: 50, width: 100,),
              Column(
                children: const [
                  Text(' - artillery unit', textScaleFactor: 1.5,),
                  Text('very slowly target', textScaleFactor: 1,),
                ],
              ),
            ],
          ),//sau
        );
      }
      l.add(const SizedBox(height: 12,));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: l,
    );
  }

  _go(context){
    Navigator.pop(context, 'GO');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mission description'),),
      body: SafeArea(
        minimum: const EdgeInsets.all(14),
        child: Center(
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('Mission ${mission.missionNumber+1}', textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
              const SizedBox(height: 12,),
              Text(mission.missionName, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
                  color: Colors.blue
                ),),
              const SizedBox(height: 18,),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.green
                ),
                child: Container(
                 decoration: const BoxDecoration(
//                    image: DecorationImage(
//                      image: AssetImage("assets/ukraine.png"),
//                      fit: BoxFit.cover,
//                    ),
                    color: Colors.white54,
                  ),
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  child: Text('Your goal:\n Hit ${mission.tanksToHit} '
                      'tank${mission.tanksToHit==1?'':'s'} in ${mission.accumulatorLifeMin} '
                      'minutes with ${mission.bombsQuantity} bombs only!',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 32,),
              Text('your target${mission.targets.length==1?'':'s'}:', textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, ),
              ),
              const SizedBox(height: 12,),
              possibleTargetsW(),
              const SizedBox(height: 32,),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          _go(context);
        },
        child: const Text('GO',style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),)
      ) ,
    );
  }
}
