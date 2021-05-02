import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:town_game/core/current_user.dart';
import 'package:town_game/core/di.dart';
import 'game.dart';

final GlobalKey<FormBuilderState> fbKey = GlobalKey<FormBuilderState>();

class CreateGame extends StatefulWidget {
  const CreateGame({Key key}) : super(key: key);

  @override
  _CreateGameState createState() => _CreateGameState();
}

final CurrentUser currentUser = getIt();
double numKillers = 2;
double minutes = 5;
bool isCreating=false;

class _CreateGameState extends State<CreateGame> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isCreating=false;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
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
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          image: DecorationImage(
              fit: BoxFit.fill, image: AssetImage('lib/assets/town.jpg')),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Text("צור משחק חדש",
                  style: TextStyle(color: Colors.white, fontSize: 40)),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white24,
                    ),
                    color: Colors.black45,
                    borderRadius: BorderRadius.all(Radius.circular(20))),
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.70,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(height: 15),
                    FormBuilder(
                      key: fbKey,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.4,
                        color: Colors.white,
                        child: NameTextField(
                          name: "userName",
                          lableText: 'שם שחקן',
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    Text("כמות רוצחים",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("${numKillers.round()}",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    //
                    SizedBox(height: 8),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: Slider(
                        activeColor: Colors.white,
                        label: numKillers.round().toString(),
                        min: 1.0,
                        max: 4.0,
                        divisions: 9,
                        onChanged: (numberPicked) {
                          setState(() {
                            numKillers = numberPicked;
                          });
                        },
                        value: numKillers,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text("זמן משחק",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("${minutes.round()}" + " :דקות לסיבוב",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    //
                    SizedBox(height: 8),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: Slider(
                        activeColor: Colors.white,
                        label: minutes.round().toString(),
                        min: 2.0,
                        max: 10.0,
                        divisions: 8,
                        onChanged: (newRating) {
                          setState(() {
                            minutes = newRating;
                          });
                        },
                        value: minutes,
                      ),
                    ),
                    SizedBox(height: 30),
                    Container(
                      height: 50.0,
                      margin: EdgeInsets.all(10),
                      child: RaisedButton(
                        onPressed: () async {
                          setState(() {
                            isCreating = true;
                          });
                          fbKey.currentState.saveAndValidate();
                          String playerName =
                              fbKey.currentState.value['userName'];
                          currentUser.name = playerName;
                          currentGame.clockMinutes = minutes.round();
                          await createGame(minutes, numKillers, playerName);

                          Future.delayed(Duration(seconds: 1), () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => Game()),
                            );
                          });
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
                            constraints: BoxConstraints(
                                maxWidth: 250.0, minHeight: 50.0),
                            alignment: Alignment.center,
                            child: !isCreating?Text(
                              "צור משחק",
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.white, fontSize: 15),
                            ):CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.05,
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> createGame(
      double minutes, double numKillers, String playerName) async {
    await FirebaseFirestore.instance.collection('Games').add({
      'roundTime': minutes,
      'numKillers': numKillers,
      // 'timerStart':false,
      'turn': 0
    }).then((docRef) {
      currentGame.gameId = docRef.id;
      currentGame.numOfKillers = numKillers.round();
    });
    currentGame.isAdmin = true;

    await FirebaseFirestore.instance
        .collection('Games')
        .doc(currentGame.gameId)
        .update({'gameCode': currentGame.gameId.substring(0, 6)});

    await FirebaseFirestore.instance
        .collection('Games')
        .doc(currentGame.gameId)
        .collection('Players')
        .add({
      'playerName': playerName,
      'role':'citizen',
      'killed':false
    });
  }
}

class NameTextField extends StatelessWidget {
  final String name;
  final String lableText;

  const NameTextField({Key key, @required this.name, this.lableText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FormBuilderTextField(
            initialValue: currentUser.name,
            inputFormatters: [],
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
