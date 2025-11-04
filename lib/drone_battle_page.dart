import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'ZoomableImage.dart';
import 'globals.dart';

class DroneBattlePage extends StatefulWidget {
  const DroneBattlePage({super.key, required this.mission});

  final Mission mission;

  @override
  State<DroneBattlePage> createState() => _DroneBattlePageState();
}

class _DroneBattlePageState extends State<DroneBattlePage> {
  String mapName = 'd1';

  @override
  void initState() {
    super.initState();
    glCurrentMission = widget.mission;
    glTanksPerMap = widget.mission.tanksPerMap;
    glTanksToKill = widget.mission.tanksToHit;
    glBombsQuantity = widget.mission.bombsQuantity;
    glAccumulatorLifeTime = widget.mission.accumulatorLifeMin;
    glAccumulatorLifeSeconds = glAccumulatorLifeTime * 60;
    //WidgetsBinding.instance.addPostFrameCallback((_) => _showTip(context));
    var r = Random();
    mapName = 'd${r.nextInt(3)+1}';
    printD('\nmapName $mapName\n');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TankCubit(),
      child: Scaffold(
        appBar: AppBar(
            title: Row(
              children: [
                Text(widget.mission.missionName),
                const Spacer(),
                BlocBuilder<TankCubit, CommonData>(
                  buildWhen: (previousState, state) {
                    return true;
                  },
                  builder: (context, cData) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/bomb.png', height: 20,),
                      const SizedBox(width: 6,),
                      Text('${cData.bombsQuantity}'),
                      const SizedBox(width: 10,),
                      RotatedBox(
                        quarterTurns: 1,
                        child: Image.asset('assets/tank.png', width: 30,)
                      ),
                      const SizedBox(width: 6,),
                      Text('${cData.killedCounter} / ${cData.restOfTanks}'),
                    ],
                  ),
                ),
              ],
            )
        ),
        body: BattleField('assets/$mapName.jpeg', scale: 3),
      )
    );
  }
}
