import 'about.dart';
import 'missionDescription.dart';
import 'teach2Dmode.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'drone_battle_page.dart';
import 'globals.dart';
import 'package:avatar_glow/avatar_glow.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dronomania',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DroneStartPage()
    );
  }
}

class DroneStartPage extends StatefulWidget {
  const DroneStartPage({Key? key}) : super(key: key);

  @override
  State<DroneStartPage> createState() => _DroneStartPageState();
}

class _DroneStartPageState extends State<DroneStartPage> {
  bool is2dTraining = false;

  @override
  void initState() {
    super.initState();
    getBestResults(context, name: 'prykhozhenko').then((value){
      printD('got getBestResults $value');
      if (value == null) {
        return;
      }
      if (value == 1) {
        is2dTraining = true;
        setState((){});
      }
    });
    _readMissionResults();
  }

  _readMissionResults() async {
    await glRestoreMRL();
    if (mounted) {
      setState(() {});
    }
  }

  _reset(){
    glDroneLife = 100;
  }

  _runMission(String name, Mission mission, int lineNumber) async {
    _reset();
    var result = await Navigator.push(context,
        MaterialPageRoute(builder: (context) => MissionDescription(mission: mission))
    );
    if (result == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    result = await Navigator.push(context,
        MaterialPageRoute(builder: (context) => DroneBattlePage(mission: mission))
    );
    if (result == null) {
      return;
    }
    if (result != 'win') {
      if (mounted) {
        await showResultPage(context, 'MISSION FAILED', result, false);
      }
    } else {
      _saveMissionWin(mission, lineNumber);
      if (mounted) {
        await showResultPage(context, 'YOU WIN!!!', '', true);
      }
    }
  }

  _saveMissionWin(Mission mission, int lineNumber){
    int idx = missionResultList.indexWhere(
            (element) => element.missionName == mission.missionName);
    MissionResult mr = MissionResult();
    if (idx == -1) {
      mr.missionName = mission.missionName;
      mr.missionIdx = lineNumber;
      mr.bestTime = glPassedFor;
      missionResultList.add(mr);
      printD('mission result saved');
    } else {
      mr = missionResultList[idx];
      if (mr.bestTime > glPassedFor) {
        mr.bestTime = glPassedFor;
        printD('best time updated');
      }
    }
    glSaveMRL();
    setState(() {});
  }

  Widget medalsW(int missionNumber){
    int idx = missionResultList.indexWhere((element) => element.missionIdx == missionNumber);
    if (idx > -1) {
      MissionResult mr = missionResultList[idx];
      return Text('best time ${mr.bestTime.toStringAsFixed(0)} sec');
    }
    return const SizedBox();
  }

  _run2dTraining() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (context) => const Teach2D(title: '2D mode'))
    );
  }

  List <Widget> missionsWL(){
    List <Widget> mwl = [];
    if (is2dTraining) {
      mwl.add(
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24,),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple
                ),
                onPressed: _run2dTraining,
                child: const Text('2D training', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 15,),
            ],
          )
      );
      mwl.add(const Divider(thickness: 2,));
    }
    mwl.add(
      const Padding(
        padding: EdgeInsets.all(15.0),
        child: Text('Mission list', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      )
    );
    for (int idx=0; idx< missions.length; idx++) {
      Mission mission = missions[idx];
      mission.missionNumber = idx;
      mwl.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent.withOpacity(0.2)
                ),
                child: Text('${idx+1}. ${mission.missionName}', textScaleFactor: 1.3,
                  style: TextStyle(
                    color: Colors.white
                  ),
                ),
                onPressed: (){
                  _runMission('Mission $idx', mission, idx);
                },
              ),
              const SizedBox(width: 6,),
              medalsW(idx),
            ],
          )
      );
      mwl.add(const SizedBox(height: 20,));
    }
    mwl.add(const SizedBox(height: 80,));
    return mwl;
  }

  _u24() async {
    await launchUrl(Uri.parse('https://u24.gov.ua/dronation'));
    printD('+');
    glExtraSpeedBombsQuantity = 5;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(
        children: [
          Image.asset('assets/ukraine.png', width: 40,),
          const SizedBox(width: 12,),
          const Text('Drone war'),
          const Spacer(),
          IconButton(
              onPressed: (){
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const About())
                );
              },
              icon: const Icon(Icons.help, size: 24,),
          ),
        ]),
      ),
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/bg2.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: ListView(
            children: [
              ...missionsWL(),
            ]
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarGlow(
            endRadius: 90,
            child: SizedBox(
              width: 120, height: 120,
              child: FloatingActionButton(
                backgroundColor: Colors.blue.withOpacity(0.1),
                onPressed: _u24,
                child: ClipOval(
                  child: Image.asset('assets/u24.jpg', width: 100, height: 100,),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/bomb2.png', height: 35,),
              const SizedBox(width: 10,),
              Text('$glExtraSpeedBombsQuantity', style: const TextStyle(
                  fontSize: 24,
                  color: Colors.yellow
              ),),
            ],
          ),
        ],
      ),
    );
  }
}

