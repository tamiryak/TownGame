import 'package:flutter/material.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:town_game/core/current_game.dart';
import 'package:town_game/core/current_user.dart';
import 'package:town_game/core/di.dart';
import 'package:town_game/main.dart';

class SettingsApp extends StatefulWidget {
  SettingsApp({Key key, bool sound, this.name}) : super(key: key);
  String name;
  @override
  _SettingsAppState createState() => _SettingsAppState();
}

TextEditingController _textFieldController = TextEditingController(); //text editor controler
SharedPreferences prefs;
int avatar;
final CurrentGame currentGame = getIt();
final CurrentUser currentUser = getIt();

class _SettingsAppState extends State<SettingsApp> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar( //app bar style
          leadingWidth: 80,

          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: FlatButton.icon( //back button
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios, color: Colors.white70),
            label: Text("  "),
          ),
        ),
        body: Container( //background
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              image: DecorationImage(
                  fit: BoxFit.fill, image: AssetImage('lib/assets/town.jpg')),
            ),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding( //title of page
                    padding: const EdgeInsets.only(top: 60),
                    child: Text("הגדרות",
                        style: TextStyle(color: Colors.white, fontSize: 40)),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(bottom: 50),
                      child: Container(
                        decoration: BoxDecoration( //create container for style of page
                            border: Border.all(
                              color: Colors.white24,
                            ),
                            color: Colors.black45,
                            borderRadius:
                                BorderRadius.all(Radius.circular(20))),
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.70,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 80.0),
                              child: Text("My Avatar", 
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 25)),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20.0),
                              child: ClipRRect( //change my avatar circle button
                                borderRadius: BorderRadius.circular(100),
                                child: InkWell(
                                  onTap: () async {
                                    await _neverSatisfied(context); //open dialog of choosing avatar
                                    prefs =
                                        await SharedPreferences.getInstance();
                                    setState(() {
                                      avatar = prefs.getInt('AVATAR'); //set the avatar to show on page
                                    });
                                  },
                                  child: (currentUser.avatar == null) //if user dont have avatar saved
                                      ? Container( //showing the change avatar style
                                          width: 120,
                                          height: 120,
                                          color: Colors.grey[600],
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .my_library_add_rounded,
                                                      color: Colors.white60,
                                                      size: 30,
                                                    ),
                                                    Text("Change Avatar",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white60))
                                                  ]),
                                            ],
                                          ),
                                        )
                                      : Container( //showing the avatar he chose
                                          width: 120,
                                          height: 120,
                                          decoration: new BoxDecoration(
                                              image: new DecorationImage(
                                            image: new AssetImage(
                                                "lib/assets/avatars/${currentUser.avatar + 1}.png"),
                                            fit: BoxFit.fill,
                                          ))),
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Row( //name and edit name line
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Name:",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 20),
                                    ),
                                    SizedBox(width: 20),
                                    Text(
                                      widget.name,
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 18),
                                    ),
                                    SizedBox(width: 20),
                                    GestureDetector( //if user pressed on edit name
                                        onTap: () async {
                                          await _displayTextInputDialog( //display dialog of changing name
                                              context);
                                          setState(() {
                                            widget.name = currentUser.name; //set the new name on page
                                          });
                                        },
                                        child: Icon(Icons.edit,
                                            color: Colors.white60))
                                  ],
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Music SFX:",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 20),
                                    ),
                                    Switch( //switch of turning on/off music
                                      value: soundOn,
                                      onChanged: (value) async {
                                        prefs = await SharedPreferences
                                            .getInstance();
                                        prefs.setBool('SOUND', value); //save on preferences the current state of sound
                                        setState(() {
                                          soundOn = value;
                                        });
                                        if (soundOn) //play the music if user chose for it
                                          FlameAudio.bgm
                                              .play('background_music.mp3');
                                        else if (!soundOn)
                                          FlameAudio.bgm.stop();
                                      },
                                      //style of switch
                                      activeTrackColor: Colors.green,
                                      inactiveTrackColor: Colors.grey,
                                      activeColor: Colors.white,
                                    ),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                      ))
                ])));
  }
}

//change name dialog
Future<void> _displayTextInputDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('שם השחקן'), //title for dialog
        content: TextField( //text field of the dialog
          controller: _textFieldController,
          decoration: InputDecoration(hintText: "כאן תרשום את השם"), 
        ),
        actions: <Widget>[
          FlatButton( //button for cancel
            child: Text(
              'בטל',
              textAlign: TextAlign.center,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          FlatButton( //button for saving new name
            child: Text(
              'שמור',
              textAlign: TextAlign.center,
            ),
            onPressed: () async {
              print(_textFieldController.text);
              String name = _textFieldController.text; //saving name he wrote
              currentUser.name = name;
              prefs = await SharedPreferences.getInstance(); 
              prefs.setString('NAME', name); //save name on preferences 
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}

Future<void> _neverSatisfied(BuildContext context) async {
  return showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: false, // user must tap button!
      builder: (context) {
        return new AlertDialog(
            contentPadding: const EdgeInsets.all(10.0),
            title: new Text( //title
              'Avatars', 
              style: new TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black),
            ),
            content: new Container(
                color: Colors.black54,
                // Specify some width
                width: MediaQuery.of(context).size.width * .7,
                height: MediaQuery.of(context).size.height * .5,
                child: new GridView.builder(
                    padding: const EdgeInsets.all(4.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      mainAxisSpacing: 4.0,
                      crossAxisSpacing: 4.0,
                      crossAxisCount: 4,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: 25, 
                    itemBuilder: (context, i) { //creating the list for the grid
                      return new GridTile(
                          child: GestureDetector( //every avatar has on tap situation
                        onTap: () async {
                          prefs = await SharedPreferences.getInstance();
                          prefs.setInt('AVATAR', i); //set the avatar on user preferences for reuse
                          currentUser.avatar = i;
                          Navigator.of(context).pop();
                        },
                        child: new Image.asset(
                          'lib/assets/avatars/${i + 1}.png', //set the right avatar he chose (avatars start from 1.png and the list start from 0)
                          fit: BoxFit.cover,
                          width: 12.0,
                          height: 12.0,
                        ),
                      ));
                    })),
            actions: <Widget>[
              new IconButton( //done button if u prefer not to choose yet
                  splashColor: Colors.green,
                  icon: new Icon(
                    Icons.done,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  })
            ]);
      });
}
