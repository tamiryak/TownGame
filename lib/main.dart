import 'package:firebase_core/firebase_core.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:town_game/presentation/create_game.dart';
import 'package:town_game/presentation/join_game.dart';
import 'package:town_game/presentation/settings.dart';
import 'package:town_game/core/di.dart' as di;

import 'core/current_user.dart';
import 'core/di.dart';

SharedPreferences prefs;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs =
      await SharedPreferences.getInstance(); //AVATAR - NAME - SOUND Preferences
  await Firebase.initializeApp();
  di.setup();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // themeMode: ThemeMode.dark,
      home: Town(),
    );
  }
}

class Town extends StatefulWidget {
  Town({Key key}) : super(key: key);

  @override
  _TownState createState() => _TownState();
}

bool soundOn =
    prefs.getBool('SOUND') ?? true; //check user preferences sound on/of
final CurrentUser currentUser = getIt();

class _TownState extends State<Town> {
  @override
  void initState() {
    super.initState();
    FlameAudio.bgm.initialize();
    if (soundOn)
      FlameAudio.bgm.play('background_music.mp3'); //initizalize the sound sfx
    currentUser.name =
        prefs.getString('NAME') ?? ""; //get the name and avatar of user
    currentUser.avatar = prefs.getInt('AVATAR');
  }

  @override
  void dispose() {
    super.dispose();
    FlameAudio.bgm.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Future<bool> _onWillPop() async {
      //dialog for exit the game
      return (await showDialog(
            context: context,
            builder: (context) => new AlertDialog(
              title: new Text('אתה בטוח?'),
              content: new Text('האם אתה בטוח שאתה רוצה לצאת?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: new Text('לא'),
                ),
                TextButton(
                  onPressed: () => SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
                  child: new Text('כן'),
                ),
              ],
            ),
          )) ??
          false;
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
            //app bar style
            leadingWidth: 80,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: IconButton(
                  //setting button on top
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SettingsApp(
                              sound: soundOn,
                              name: currentUser.name)), //moving to setting page
                    );
                  },
                  icon: Icon(Icons.settings)),
            )),
        body: Container(
          // body of scaffold - two buttons and background configuration
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            //background config
            image: DecorationImage(
                fit: BoxFit.fill,
                image: AssetImage('lib/assets/background_town.jpg')),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: 50.0,
                margin: EdgeInsets.all(10),
                child: RaisedButton(
                  //first button - moving to create game page
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreateGame()),
                    );
                  },
                  shape: RoundedRectangleBorder(
                      //style of first button
                      borderRadius: BorderRadius.circular(80.0)),
                  padding: EdgeInsets.all(0.0),
                  child: Ink(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.brown, Color(0xff3b1d1c)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(30.0)),
                    child: Container(
                      constraints:
                          BoxConstraints(maxWidth: 250.0, minHeight: 50.0),
                      alignment: Alignment.center,
                      child: Text(
                        "צור משחק חדש",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 50.0,
                margin: EdgeInsets.all(10),
                child: RaisedButton(
                  // second button - join game, moving to join game page
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => JoinGame()),
                    );
                  },
                  shape: RoundedRectangleBorder(
                      //join game button style
                      borderRadius: BorderRadius.circular(80.0)),
                  padding: EdgeInsets.all(0.0),
                  child: Ink(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.brown, Color(0xff3b1d1c)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(30.0)),
                    child: Container(
                      constraints:
                          BoxConstraints(maxWidth: 250.0, minHeight: 50.0),
                      alignment: Alignment.center,
                      child: Text(
                        "משחק קיים",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.1,
              )
            ],
          ),
        ),
      ),
    );
  }
}
