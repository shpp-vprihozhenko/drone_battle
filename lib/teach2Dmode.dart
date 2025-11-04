import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'globals.dart';
import 'battle.dart';

class Teach2D extends StatefulWidget {
  const Teach2D({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<Teach2D> createState() => _Teach2DState();
}

class _Teach2DState extends State<Teach2D> {

  @override
  void initState() {
    super.initState();
    getBestResults(context).then((value){
      print('got val $value');
      if (value == null) {
        return;
      }
      value.forEach((vue){
        UserResult ur = UserResult();
        ur.name = vue["name"];
        ur.score = vue["score"];
        url.add(ur);
      });
      setState((){});
    });
  }

  _askHeroName() async {
    TextEditingController tecName = TextEditingController();
    var result = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Container(
                width: 300, height: 300,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('You are cool!'),
                      const SizedBox(height: 14,),
                      const Text('Enter your name, hero:'),
                      const SizedBox(height: 10,),
                      TextField(
                        controller: tecName,
                      ),
                      const SizedBox(height: 20,),
                      ElevatedButton(
                          onPressed: () async {
                            if (tecName.text.trim() == '') {
                              await showAlertPage(context, 'Enter your name please');
                              return;
                            }
                            Navigator.pop(context, tecName.text);
                          },
                          child: const Text('OK')
                      ),
                    ],
                  ),
                )
            ),
          );
        }
    );
    //tecName.dispose();
    if (result == null) {
      return;
    }
    print('got name $result');
    return result;
  }

  _showBest10() async {
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: SizedBox(
                width: 300, height: 300,
                child: ListView(
                  children: [
                    const Text('Best heroes\nof the month',
                      style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold,
                        color: Colors.purple
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18,),
                    ListView.builder(
                        shrinkWrap: true,
                        itemCount: url.length,
                        itemBuilder: (context, idx) {
                          UserResult ur = url[idx];
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Row(
                              children: [
                                Expanded(child: Text(ur.name)),
                                const SizedBox(width: 12,),
                                Text(ur.score.toString())
                              ],
                            ),
                          );
                        }
                    ),
                    const SizedBox(height: 20,),
                  ],
                )
            ),
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    Size fieldSize = MediaQuery.of(context).size;
    printD('fieldSize $fieldSize');
    AppBar appBar = AppBar(
      title: Text(widget.title),
    );
    double appHeight = appBar.preferredSize.height;
    double topPadding =  MediaQuery.of(context).padding.top;
    double bodyHeight = fieldSize.height-appHeight-topPadding;
    printD('appHeight $appHeight topPadding $topPadding bodyHeight $bodyHeight');
    double blueHeight = bodyHeight/2;
    double yellowHeight = fieldSize.height-blueHeight;
    return Scaffold(
      appBar: appBar,
      body: Stack(
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
            left: 0, top: 0,
            child: Container(
              width: fieldSize.width,
              height: bodyHeight,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  //shrinkWrap: true,
                  children: [
                    liveCounter+deadCounter == 0?
                    const SizedBox()
                        :
                    SizedBox(
                      width: fieldSize.width,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text ('killed enemies: ', style: TextStyle(fontSize: 30),),
                              Text(deadCounter.toString(),
                                style: const TextStyle(fontSize: 36, color: Colors.red, fontWeight: FontWeight.bold),),
                            ],
                          ),
                          const SizedBox(height: 15,),
                          GestureDetector(
                              onTap: _showBest10,
                              child: Image.asset('assets/top10.png', width: 90, height: 90,)
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        liveCounter = 0; deadCounter = 0;
                        await Navigator.push(context,
                            MaterialPageRoute(builder: (context) => const Battle())
                        );
                        if (url.isEmpty || deadCounter > url.last.score) {
                          var name = await _askHeroName();
                          if (name == null) {
                            setState((){});
                            return;
                          }
                          UserResult ur = UserResult();
                          ur.name = name;
                          ur.score = deadCounter;
                          url.add(ur);
                          addBestResult(context, name, deadCounter);
                        }
                        setState((){});
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          AvatarGlow(
                            glowColor: Colors.black,
                            endRadius: 90,
                            child: ClipOval(
                              child: Container(
                                  color: Colors.white,
                                  width: 140, height: 140,
                                  child: Center(
                                      child: Image.asset('assets/drone.png')
                                    //Text('GO', style: TextStyle(fontSize: 55),)
                                  )
                              ),
                            ),
                          ),
                          const Text('START', style: TextStyle(
                              fontSize: 40, fontWeight: FontWeight.bold
                          ),)
                        ],
                      ),
                    ),
                    const SizedBox(height: 12,),
                    liveCounter+deadCounter == 0?
                    const SizedBox()
                        :
                    GestureDetector(
                      onTap: (){
                        launchUrl(Uri.parse('https://u24.gov.ua/dronation'));
                      },
                      child: SizedBox(
                        width: fieldSize.width,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/u24dronesFond.jpg',
                                  width: fieldSize.width*0.9,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14,),
                            const Text('do your bit for peace',
                              style: TextStyle(fontSize: 32,
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
