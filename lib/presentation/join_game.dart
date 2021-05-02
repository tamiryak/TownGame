import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:town_game/core/current_user.dart';
import 'package:town_game/core/di.dart';

import 'game.dart';

final GlobalKey<FormBuilderState> fbKey = GlobalKey<FormBuilderState>();
bool gameCodeValid = true;

class JoinGame extends StatefulWidget {
  const JoinGame({Key key}) : super(key: key);

  @override
  _JoinGameState createState() => _JoinGameState();
}

final CurrentUser currentUser = getIt();
bool isJoining=false;

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
        // backgroundColor: Colors.white70,
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
                child: !isJoining?Text("הצטרף למשחק",
                    style: TextStyle(color: Colors.white, fontSize: 40)):CircularProgressIndicator(),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: TextFieldsEditor(),
                  ),
                  Container(
                    height: 50.0,
                    margin: EdgeInsets.all(10),
                    child: RaisedButton(
                      onPressed: () async {
                        isJoining=true;
                        fbKey.currentState.saveAndValidate();
                        String playerName =
                            fbKey.currentState.value['guestName'];
                        String gameCode = fbKey.currentState.value['gameCode'];
                        currentUser.name = playerName;
                        currentGame.isAdmin = false;
                        await joinGame(playerName, gameCode);
                        gameCodeValid
                            ? Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => Game()),
                              )
                            : SnackBar(
                                content: Text('הקוד שהזנת שגוי'),
                              );
                      },
                      shape: RoundedRectangleBorder(
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

  joinGame(String playerName, String gameCode) async {
    
    await FirebaseFirestore.instance
        .collection('Games')
        .where('gameCode', isEqualTo: gameCode)
        .get()
        .then((snapshot) {
      if (snapshot.docs.length > 0) {
        currentGame.gameId = snapshot.docs[0].id;
        setState(() {
          gameCodeValid = true;
        });
      } else {
        setState(() {
          gameCodeValid = false;
        });
      }
    });
    if (gameCodeValid)
      await FirebaseFirestore.instance
          .collection('Games')
          .doc(currentGame.gameId)
          .collection('Players')
          .add({
        'playerName': playerName,
        'role':'citizen',
        'killed':false
      });

        await FirebaseFirestore.instance
          .collection('Games')
          .doc(currentGame.gameId)
          .get().then((value) => currentGame.clockMinutes= (value['roundTime']).round());


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
            initialValue: currentUser.name,
            inputFormatters: [
              if (digitOnly) FilteringTextInputFormatter.digitsOnly
              // else
              //   FilteringTextInputFormatter.allow(
              //     RegExp("[a-zA-Z0-9]"),
              //   ),
              // LengthLimitingTextInputFormatter(4),
            ],
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
