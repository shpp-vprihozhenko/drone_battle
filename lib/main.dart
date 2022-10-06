import 'package:flutter/material.dart';
import 'package:seabattle/globals.dart';
import 'battle.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Drone Battle'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

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
                      Text('You are cool!'),
                      SizedBox(height: 14,),
                      Text('Enter your name, hero:'),
                      SizedBox(height: 10,),
                      TextField(
                        controller: tecName,
                      ),
                      SizedBox(height: 20,),
                      ElevatedButton(
                          onPressed: () async {
                            if (tecName.text.trim() == '') {
                              await showAlertPage(context, 'Enter your name please');
                              return;
                            }
                            Navigator.pop(context, tecName.text);
                          },
                          child: Text('OK')
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
            content: Container(
              width: 300, height: 300,
              child: Column(
                children: [
                  Text('Best heroes of the month'),
                  SizedBox(height: 18,),
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
                            SizedBox(width: 12,),
                            Text(ur.score.toString())
                          ],
                        ),
                      );
                    }
                  ),
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
    double blueHeight = fieldSize.height/2-55;
    double yellowHeight = fieldSize.height-blueHeight;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
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
          liveCounter+deadCounter == 0?
            const SizedBox()
          :
            Positioned(
            top: blueHeight/3, left: 0,
            child: SizedBox(
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
                  SizedBox(height: 15,),
                  GestureDetector(
                    onTap: _showBest10,
                    child: Image.asset('assets/top10.png', width: 90, height: 90,)
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: fieldSize.width, height: fieldSize.height,
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  liveCounter = 0; deadCounter = 0;
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Battle())
                  );
                  if (url.length == 0 || deadCounter > url.last.score) {
                    var name = await _askHeroName();
                    if (name == null) {
                      print('no name');
                      setState((){});
                      return;
                    }
                    print('ok name $name');
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
                    ClipOval(
                      child: Container(
                        color: Colors.white,
                        width: 140, height: 140,
                          child: Center(
                            child: Image.asset('assets/drone.png')
                            //Text('GO', style: TextStyle(fontSize: 55),)
                          )
                      ),
                    ),
                    const Text('START', style: TextStyle(
                      fontSize: 40, fontWeight: FontWeight.bold
                    ),)
                  ],
                ),
              ),
            ),
          ),
          liveCounter+deadCounter == 0?
            const SizedBox()
          :
            Positioned(
            top: blueHeight+100,
            child: GestureDetector(
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
          ),
        ],
      ),
    );
  }
}
