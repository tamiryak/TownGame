import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:town_game/core/current_user.dart';
import 'package:town_game/core/di.dart';

import 'game.dart';

final GlobalKey<FormBuilderState> fbKey =
    GlobalKey<FormBuilderState>(); //form builder key
bool gameCodeValid = true; //boolean check if user entered valid code
DateTime loginClickTime;

bool isRedundentClick(DateTime currentTime) {
  if (loginClickTime == null) {
    loginClickTime = currentTime;
    print("first click");
    return false;
  }
  print('diff is ${currentTime.difference(loginClickTime).inSeconds}');
  if (currentTime.difference(loginClickTime).inSeconds < 4) {
    //set this difference time in seconds
    return true;
  }

  loginClickTime = currentTime;
  return false;
}

class JoinGame extends StatefulWidget {
  const JoinGame({Key key}) : super(key: key);

  @override
  _JoinGameState createState() => _JoinGameState();
}

final CurrentUser currentUser = getIt();
bool isJoining = false; //change the state of joining
bool snackBar = false;

class _JoinGameState extends State<JoinGame> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isJoining = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        //back button
        leadingWidth: 80,

        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: FlatButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: Colors.white70),
          label: Text("  "),
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: Container(
        //background
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          image: DecorationImage(
              fit: BoxFit.fill, image: AssetImage('lib/assets/town.jpg')),
        ),
        child: FormBuilder(
          key: fbKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: !isJoining
                    ? Text("הצטרף למשחק",
                        style: TextStyle(color: Colors.white, fontSize: 40))
                    : CircularProgressIndicator(),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: TextFieldsEditor(), //showing the text fields
                  ),
                  Container(
                    height: 50.0,
                    margin: EdgeInsets.all(10),
                    child: RaisedButton(
                      //button for entering to game
                      onPressed: () async {
                        if (fbKey.currentState.validate()) {
                          if (isRedundentClick(DateTime.now())) {
                            print('hold on, processing');
                            return;
                          }
                          fbKey.currentState.saveAndValidate();
                          String playerName = fbKey.currentState.value[
                              'guestName']; //saving the player name on var
                          String gameCode = fbKey.currentState
                              .value['gameCode']; //saving the game code on var
                          currentUser.name =
                              playerName; //saving the name for reuse
                          currentGame.isAdmin = false;
                          await joinGame(
                              playerName, gameCode); //join the game on firebase
                          gameCodeValid
                              ? Navigator.push(
                                  //if code valid - moving to game page (list of all players)
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          Game()), //moving to game (player list page)
                                )
                              : isJoining = false;
                        }
                      },
                      shape: RoundedRectangleBorder(
                          //button style
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
                            "הצטרף למשחק",
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
            ],
          ),
        ),
      ),
    );
  }

  //join game on firebase
  joinGame(String playerName, String gameCode) async {
    await FirebaseFirestore.instance
        .collection('Games')
        .where('gameCode', isEqualTo: gameCode) //searching for the right game
        .get()
        .then((snapshot) {
      if (snapshot.docs.length > 0) {
        currentGame.gameId = snapshot.docs[0].id; //get the id of it
        setState(() {
          gameCodeValid = true;
        });
      } else {
        setState(() {
          gameCodeValid = false;
        });
      }
    });
    if (gameCodeValid) //if the game exist - creating the player in list of players in game
      await FirebaseFirestore.instance
          .collection('Games')
          .doc(currentGame.gameId)
          .collection('Players')
          .add({
        'playerName': playerName,
        'role': 'citizen',
        'killed': false,
        'avatar': currentUser.avatar
      });

    await FirebaseFirestore
        .instance //saving the round time and the number of killer player 1 choose
        .collection('Games')
        .doc(currentGame.gameId)
        .get()
        .then((value) {
      currentGame.clockMinutes = (value['roundTime']).round();
      currentGame.numOfKillers = (value['numKillers']).round();
    });
  }
}

class TextFieldsEditor extends StatefulWidget {
  TextFieldsEditor({Key key}) : super(key: key);

  @override
  _TextFieldsEditorState createState() => _TextFieldsEditorState();
}

class _TextFieldsEditorState extends State<TextFieldsEditor> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.6,
            color: Colors.white,
            child: EventTextField(
              name: "guestName",
              lableText: 'שם שחקן',
              digitOnly: false,
            ),
          ),
          SizedBox(height: 20),
          Container(
            width: MediaQuery.of(context).size.width * 0.6,
            color: Colors.white,
            child: EventTextField(
              name: "gameCode",
              lableText: 'קוד הצטרפות',
              digitOnly: false,
            ),
          ),
        ],
      ),
    );
  }
}

class EventTextField extends StatelessWidget {
  final String name;
  final String lableText;
  final bool multiline;
  final bool digitOnly;
  const EventTextField(
      {Key key,
      this.multiline = false,
      @required this.name,
      this.lableText,
      @required this.digitOnly})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FormBuilderTextField(
            initialValue: (this.name == "guestName")
                ? currentUser.name
                : "", //if username was saved
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(context),
              FormBuilderValidators.max(context, 20),
            ]),
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: lableText,
            ),
            name: name,
          ),
        ),
      ],
    );
  }
}
