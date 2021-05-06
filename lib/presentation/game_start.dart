import 'package:circle_list/circle_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:town_game/core/current_game.dart';
import 'package:town_game/core/current_user.dart';
import 'package:town_game/core/di.dart';
import 'package:town_game/presentation/game.dart';
import 'package:town_game/widgets/timer.dart';

import '../main.dart';

//initial values for the state
bool copIsDead = false;
bool doctorIsDead = false;
int numOfKillersLeft;
int numOfPlayersLeft;

class GameStart extends StatefulWidget {
  GameStart({Key key}) : super(key: key);

  @override
  _GameStartState createState() => _GameStartState();
}

final CurrentGame currentGame = getIt();
final CurrentUser currentUser = getIt();
CollectionReference players;
List<String> shape = ['♦','♣','♥','♠'];

class _GameStartState extends State<GameStart> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    FlameAudio.bgm.stop();
    DocumentReference games =
        FirebaseFirestore.instance.collection('Games').doc(currentGame.gameId);
    players = games.collection('Players');
    numOfKillersLeft = currentGame.numOfKillers;
    numOfPlayersLeft = currentGame.numOfPlayers;
  }

// this build moving between the frames - this actualy responsible for the game loop
  @override
  Widget build(BuildContext context) {
    Future<bool> _onWillPop() async { //dialog for exit the game
      return (await showDialog(
            context: context,
            builder: (context) => new AlertDialog(
              title: new Text('Are you sure?'),
              content: new Text('Do you want to exit an App'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: new Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) => Town())),
                  child: new Text('Yes'),
                ),
              ],
            ),
          )) ??
          false;
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: FutureBuilder(
          future: players
              .where('playerName', isEqualTo: currentUser.name)
              .limit(1)
              .get(),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else {
              currentUser.role = snapshot.data.docs[0]['role']; //the players gets their roles that was drawen for them
              return Scaffold(
                  extendBodyBehindAppBar: true,
                  appBar: AppBar(
                      actions: [
                        Container(
                          child: currentGame.isAdmin?ElevatedButton( //end game button
                              child: Text("End Game".toUpperCase(),
                                  style: TextStyle(fontSize: 14)),
                              style: ButtonStyle(
                                  foregroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.white),
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.red),
                                  shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero,
                                          side:
                                              BorderSide(color: Colors.red)))),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('Games')
                                    .doc(currentGame.gameId)
                                    .update({'endGame': true}); //ending the game on firebase
                              }):Container(),
                        )
                      ],
                      //appbar style
                      leadingWidth: 80,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                            height: 50,
                            width: 50,
                            child: FlipCard(
                              back: Container( //card of the player
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(4)),
                                  color: Colors.white,
                                ),
                                child: Center(
                                  child: Text( 
                                      currentUser.role == null
                                          ? ""
                                          : currentUser.role + '\n' +(shape..shuffle()).first,
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 16),
                                      textAlign: TextAlign.center),
                                ),
                              ),
                              front: Center(
                                  child: Image.asset('lib/assets/card.jpg')),
                              flipOnTouch: true,
                            )),
                      )),
                  body: StreamBuilder( //stream builder of the game turns
                          stream: FirebaseFirestore.instance
                              .collection("Games")
                              .doc(currentGame.gameId)
                              .snapshots(),
                          builder: (ctx, dataSnapshot) {
                            if (dataSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Container(
                                  height: MediaQuery.of(context).size.height,
                                  width: MediaQuery.of(context).size.width,
                                  child: Center(
                                      child: CircularProgressIndicator()));
                            } else {
                              if (dataSnapshot.error != null) {
                                // ...
                                // Do error handling stuff
                                return Center(
                                  child: Text(
                                      'An error occurred! please try again'),
                                );
                              } else {
                                var endGame = dataSnapshot.data['endGame']; //check if endgame situation
                                var turn = dataSnapshot.data['turn']; //var of the current turn 
                                //check end if some group won
                                if ((numOfKillersLeft == 0) ||
                                    (endGame == true)) turn = 7;
                                if (numOfKillersLeft >= 1 &&
                                    numOfPlayersLeft == 1) turn = 6;
                                //----------------------------
                                switch (turn) {
                                  case 1:
                                    return Day(); //if day turn (admin incharge)
                                    break;
                                  case 2:
                                    return Kill(); //if kill turn (killer incharge)
                                    break;
                                  case 3:
                                    if (!doctorIsDead)
                                      return Heal(); //if doctor turn (doctor incharge) if not dead
                                    else {
                                      changeturn(4);
                                    }
                                    break;
                                  case 4:
                                    if (!copIsDead)
                                      return Investigate(); //if investigate turn (cop incharge)
                                    else {
                                      changeturn(1);
                                    }
                                    break;
                                  //end game cases
                                  //admin chose to end the game
                                  case 5:
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (BuildContext context) =>
                                                Town()));
                                    break;
                                    //killers won
                                  case 6:
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (BuildContext context) =>
                                                Town()));
                                    break;
                                    //citizens won
                                  case 7:
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (BuildContext context) =>
                                                Town()));
                                    break;
                                    //------------------------------
                                }
                              }
                            }
                          }) ??
                      Container());
            }
          }),
    );
  }

//change to turn
  Future<void> changeturn(int turn) async {
    await FirebaseFirestore.instance
        .collection('Games')
        .doc(currentGame.gameId)
        .update({'turn': turn});
  }
}


//--------------day situation -----------------

class Day extends StatefulWidget {
  const Day({Key key}) : super(key: key);

  @override
  _DayState createState() => _DayState();
}

class _DayState extends State<Day> with TickerProviderStateMixin {
  AssetImage image;
  AnimationController _controller;
  int levelClock = (currentGame.clockMinutes) * 60; //initialize the timer round time
  bool isTimer = false;
  bool timerFinish = false;

  @override
  void initState() {
    super.initState();
    image = AssetImage("lib/assets/nighttoday.gif"); //changing from night to day
    doctorSucceed = false;

    Future.delayed(Duration(seconds: 4), () { //delaying the show of the timer animation
      _controller = AnimationController(
          vsync: this,
          duration: Duration(
              seconds:
                  levelClock) // gameData.levelClock is a user entered number elsewhere in the applciation
          )
        ..addStatusListener((AnimationStatus status) {
          if (status == AnimationStatus.completed)
            setState(() {
              isTimer = false;
              changeturn();
            });
        });

      _controller.forward();
      setState(() {
        isTimer = true;
      });
    });
  }

  @override
  void dispose() {
    image.evict();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Image(
          gaplessPlayback: true, //showing the last picture of the gif
          image: image,
          fit: BoxFit.cover,
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.18,
          child: isTimer
              ? Countdown(
                  animation: StepTween(
                    begin: levelClock, // THIS IS A USER ENTERED NUMBER for timer
                    end: 0,
                  ).animate(_controller),
                )
              : Container(),
        ),
        isTimer && currentGame.isAdmin //show the players only if admin (admin is able to choose after vote)
            ? Positioned(
                bottom: MediaQuery.of(context).size.height * 0.10,
                child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("Games")
                        .doc(currentGame.gameId)
                        .collection('Players')
                        // .where('killed', isEqualTo: false)
                        .snapshots(),
                    builder: (ctx, dataSnapshot) {
                      if (dataSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else {
                        if (dataSnapshot.error != null) {
                          // ...
                          // Do error handling stuff
                          return Center(
                            child: Text('An error occurred! please try again'),
                          );
                        } else {
                          var playersAlive = dataSnapshot.data.docs; //all players
                          return new CircleList(
                              origin: Offset(0, 0),
                              children: playersAlive
                                  .map<Widget>((DocumentSnapshot player) {
                                return player['killed'] == false //if player was killed - avatar with red x
                                    ? new Container( //else - pressable avatar
                                        width:
                                            (MediaQuery.of(context).size.width / //changing the size of the avatar by amount of players
                                                    playersAlive.length) +
                                                40,
                                        height:
                                            (MediaQuery.of(context).size.width /
                                                    playersAlive.length) +
                                                40,
                                        child: InkWell( //on player pressed - admin press on someone (kill the player)
                                          onTap: () async {
                                            await FirebaseFirestore.instance
                                                .collection('Games')
                                                .doc(currentGame.gameId)
                                                .collection('Players')
                                                .where('playerName',
                                                    isEqualTo: player['playerName'])
                                                .limit(1)
                                                .get()
                                                .then((value) {
                                              (value.docs[0])
                                                  .reference
                                                  .update({'killed': true});
                                              if (value.docs[0]['role'] ==
                                                  'doctor')
                                                doctorIsDead = true;
                                              else if (value.docs[0]['role'] ==
                                                  'cop') copIsDead = true;
                                            });
                                            changeturn(); //moving to night mode
                                          },
                                          child: ClipRRect( //avatar of player 
                                            borderRadius:
                                                BorderRadius.circular(100),
                                            child: Container(
                                                decoration: (player['avatar'] !=
                                                        null)
                                                    ? new BoxDecoration(
                                                        color: Colors.brown,
                                                        image:
                                                            new DecorationImage(
                                                          image: new AssetImage(
                                                              "lib/assets/avatars/${player['avatar'] + 1}.png"),
                                                          fit: BoxFit.fill,
                                                        ))
                                                    : BoxDecoration(
                                                        color: Colors.brown),
                                                child: Center(
                                                    child: Text(
                                                        player['playerName'],
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            backgroundColor:
                                                                Colors.black,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)))),
                                          ),
                                        ))
                                    : KilledCircle( //if the player was killed - red x circle container
                                        name: player['playerName'],
                                        avatar: player['avatar'],
                                        numOfP: playersAlive.length,
                                      );
                              }).toList());
                        }
                      }
                    }))
            : Container(),
        isTimer && currentGame.isAdmin //skip button - only for admin
            ? Positioned(
                bottom: MediaQuery.of(context).size.height * 0.05,
                child: FloatingActionButton(
                  elevation: 5,
                  backgroundColor: Colors.blueAccent,
                  child: Container(
                      width: 100,
                      height: 100,
                      child: Center(
                          child: Text(
                        "דלג",
                        textAlign: TextAlign.center,
                      ))),
                  onPressed: () async {
                    changeturn();
                  },
                ),
              )
            : Container()
      ],
    );
  }

  Future<void> changeturn() async {
    await FirebaseFirestore.instance
        .collection('Games')
        .doc(currentGame.gameId)
        .update({'turn': 2});
  }
}


//killed circle for user that is dead already
class KilledCircle extends StatelessWidget {
  const KilledCircle({
    Key key,
    @required this.name,
    this.avatar,
    this.numOfP,
  }) : super(key: key);
  final String name;
  final int avatar;
  final int numOfP;
  @override

  //building the style - avatar - red x on the avatar 
  Widget build(BuildContext context) {
    return new Container(
        width: (MediaQuery.of(context).size.width / numOfP) + 40,
        height: (MediaQuery.of(context).size.width / numOfP) + 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Container(
                  decoration: (avatar != null)
                      ? new BoxDecoration(
                          color: Colors.brown,
                          image: new DecorationImage(
                            image: new AssetImage(
                                "lib/assets/avatars/${avatar + 1}.png"),
                            fit: BoxFit.fill,
                          ))
                      : BoxDecoration(color: Colors.brown),
                  child: Center(
                      child: Text(name,
                          style: TextStyle(
                              color: Colors.white,
                              backgroundColor: Colors.black,
                              fontWeight: FontWeight.bold)))),
            ),
            Text("x",
                style: TextStyle(color: Colors.red, fontSize: 800 / numOfP))
          ],
        ));
  }
}


//-------------------------------killer decision mode-----------------


class Kill extends StatefulWidget {
  const Kill({Key key}) : super(key: key);

  @override
  _KillState createState() => _KillState();
}

class _KillState extends State<Kill> {
  AssetImage image;
  bool isKiller;
  String killerText = '';

  @override
  void initState() {
    super.initState();
    image = AssetImage("lib/assets/daytonight.gif");
    isKiller = currentUser.role == 'killer';
    Future.delayed(Duration(seconds: 4), () {
      setState(() {
        killerText = 'שלום רוצח\n ?את מי תרצה לרצוח';
      });
    });
    //print('${widget.asset} initState');
  }

  @override
  void dispose() {
    //print('${widget.asset} dispose');
    image.evict();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Image(
          image: image,
          fit: BoxFit.cover,
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
        ),
        isKiller //showing text and players only to the killer
            ? Positioned(
                top: MediaQuery.of(context).size.height * 0.22,
                child: Text(
                  killerText,
                  style: TextStyle(color: Colors.white, fontSize: 35),
                  textAlign: TextAlign.center,
                ))
            : Container(),
        isKiller
            ? Positioned(
                bottom: MediaQuery.of(context).size.height * 0.10,
                child: StreamBuilder( //stream builder for all the players in game
                    stream: FirebaseFirestore.instance
                        .collection("Games")
                        .doc(currentGame.gameId)
                        .collection('Players')
                        .snapshots(),
                    builder: (ctx, dataSnapshot) {
                      if (dataSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else {
                        if (dataSnapshot.error != null) {
                          // ...
                          // Do error handling stuff
                          return Center(
                            child: Text('An error occurred! please try again'),
                          );
                        } else {
                          var playersAlive = dataSnapshot.data.docs;
                          return new CircleList( //creating the circle list of all the players
                              origin: Offset(0, 0),
                              children: playersAlive
                                  .map<Widget>((DocumentSnapshot player) {
                                if (player['playerName'] != currentUser.name) { 
                                  player['killed'] == false
                                      ? new Container(
                                          width: (MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  playersAlive.length) +
                                              40,
                                          height: (MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  playersAlive.length) +
                                              40,
                                          child: InkWell(
                                            onTap: () async { //on killer pick a player
                                              await FirebaseFirestore.instance
                                                  .collection('Games')
                                                  .doc(currentGame.gameId)
                                                  .update({
                                                'killerPick':
                                                    player['playerName'] //saving the killer pick
                                              });
                                              await FirebaseFirestore.instance
                                                  .collection('Games')
                                                  .doc(currentGame.gameId)
                                                  .update({'turn': 3}); //moving to phase 3
                                            },
                                            child: ClipRRect( //creating the avatar of each player
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              child: Container(
                                                  decoration: (player['avatar'] !=
                                                          null)
                                                      ? new BoxDecoration(
                                                          color: Colors.brown,
                                                          image:
                                                              new DecorationImage(
                                                            image: new AssetImage(
                                                                "lib/assets/avatars/${player['avatar'] + 1}.png"),
                                                            fit: BoxFit.fill,
                                                          ))
                                                      : BoxDecoration(
                                                          color: Colors.brown),
                                                  child: Center(
                                                      child: Text(
                                                          player['playerName'],
                                                          style: TextStyle(
                                                              backgroundColor:
                                                                  Colors.black,
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)))),
                                            ),
                                          ))
                                      : KilledCircle(
                                          name: player['playerName'],
                                          avatar: player['avatar'],
                                          numOfP: playersAlive.length,
                                        );
                                }
                              }).toList());
                        }
                      }
                    }))
            : Container()
      ],
    );
  }
}


//-------------------------heal - doctor needs to pick who to save-------------

class Heal extends StatefulWidget {
  const Heal({Key key}) : super(key: key);

  @override
  _HealState createState() => _HealState();
}

bool isDoctor;
bool doctorSucceed = false;
String killerPick;

class _HealState extends State<Heal> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    doctorSucceed = false;
    isDoctor = currentUser.role == 'doctor';
    FirebaseFirestore.instance
        .collection('Games')
        .doc(currentGame.gameId)
        .get()
        .then((value) => killerPick = value['killerPick']); //getting the killer pick
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Image(
          image: Image.asset('lib/assets/night.jpg').image,
          fit: BoxFit.cover,
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
        ),
        isDoctor //assure only doctor is seeing the circle list and the text
            ? Positioned(
                top: MediaQuery.of(context).size.height * 0.22,
                child: Text(
                  'שלום רופא\n ?את מי תרצה להציל',
                  style: TextStyle(color: Colors.white, fontSize: 35),
                  textAlign: TextAlign.center,
                ))
            : Container(),
        isDoctor
            ? Positioned(
                bottom: MediaQuery.of(context).size.height * 0.10,
                child: StreamBuilder( //Stream of all players in game
                    stream: FirebaseFirestore.instance
                        .collection("Games")
                        .doc(currentGame.gameId)
                        .collection('Players')
                        .snapshots(),
                    builder: (ctx, dataSnapshot) {
                      if (dataSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else {
                        if (dataSnapshot.error != null) {
                          // ...
                          // Do error handling stuff
                          return Center(
                            child: Text('An error occurred! please try again'),
                          );
                        } else {
                          var playersAlive = dataSnapshot.data.docs;
                          return new CircleList(
                              origin: Offset(0, 0),
                              children: playersAlive
                                  .map<Widget>((DocumentSnapshot player) { //creating the circle list
                                player['killed'] == false
                                    ? new Container(
                                        width:
                                            (MediaQuery.of(context).size.width /
                                                    playersAlive.length) +
                                                40,
                                        height:
                                            (MediaQuery.of(context).size.width /
                                                    playersAlive.length) +
                                                40,
                                        child: InkWell(
                                          onTap: () async { //if doctor pick player
                                            await FirebaseFirestore.instance //check if player was killed by the killer
                                                .collection('Games')
                                                .doc(currentGame.gameId)
                                                .get()
                                                .then((snap) {
                                              if (snap['killerPick'] ==
                                                  player['playerName']) {
                                                setState(() {
                                                  doctorSucceed = true;
                                                  killerPick =
                                                      snap['killerPick'];
                                                });
                                              }
                                            });

                                            await FirebaseFirestore.instance //save rather doctor succeed or not
                                                .collection('Games')
                                                .doc(currentGame.gameId)
                                                .update({
                                              'turn': 4,
                                              'doctorSucceed': doctorSucceed
                                            });
                                          },
                                          child: ClipRRect( //each player gets avatar
                                            borderRadius:
                                                BorderRadius.circular(100),
                                            child: Container(
                                                decoration: (player['avatar'] !=
                                                        null)
                                                    ? new BoxDecoration(
                                                        color: Colors.brown,
                                                        image:
                                                            new DecorationImage(
                                                          image: new AssetImage(
                                                              "lib/assets/avatars/${player['avatar'] + 1}.png"),
                                                          fit: BoxFit.fill,
                                                        ))
                                                    : BoxDecoration(
                                                        color: Colors.brown),
                                                child: Center(
                                                    child: Text(
                                                        player['playerName'],
                                                        style: TextStyle(
                                                            backgroundColor:
                                                                Colors.black,
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)))),
                                          ),
                                        ))
                                    : KilledCircle(
                                        name: player['playerName'],
                                        avatar: player['avatar'],
                                        numOfP: playersAlive.length,
                                      );
                              }).toList());
                        }
                      }
                    }))
            : Container()
      ],
    );
  }
}


//--------------------investigate mode - cop is picking player to ask--------------


class Investigate extends StatefulWidget {
  const Investigate({Key key}) : super(key: key);

  @override
  _InvestigateState createState() => _InvestigateState();
}

bool isCop;
bool copRight;
bool picked;

class _InvestigateState extends State<Investigate> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isCop = currentUser.role == 'cop';
    copRight = false;
    picked = false;
    FirebaseFirestore.instance
        .collection('Games')
        .doc(currentGame.gameId)
        .get()
        .then((snap) {
      doctorSucceed = snap['doctorSucceed'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Image(
          image: Image.asset('lib/assets/night.jpg').image,
          fit: BoxFit.cover,
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
        ),
        isCop
            ? Positioned(
                top: MediaQuery.of(context).size.height * 0.22,
                child: Text(
                  'שלום שוטר\n ?את מי תרצה לחקור',
                  style: TextStyle(color: Colors.white, fontSize: 35),
                  textAlign: TextAlign.center,
                ))
            : Container(),
        isCop
            ? !picked
                ? Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.10,
                    child: StreamBuilder( //stream of all players in game
                        stream: FirebaseFirestore.instance
                            .collection("Games")
                            .doc(currentGame.gameId)
                            .collection('Players')
                            .snapshots(),
                        builder: (ctx, dataSnapshot) {
                          if (dataSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else {
                            if (dataSnapshot.error != null) {
                              // ...
                              // Do error handling stuff
                              return Center(
                                child:
                                    Text('An error occurred! please try again'),
                              );
                            } else {
                              var playersAlive = dataSnapshot.data.docs;
                              int i = -1;
                              return new CircleList(
                                  origin: Offset(0, 0),
                                  children: playersAlive
                                      .map<Widget>((DocumentSnapshot player) { //creating the circle list for each player
                                    if (player['playerName'] !=
                                        currentUser.name) {
                                      i++;
                                      player['killed'] == false
                                          ? new Container(
                                              width: (MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      playersAlive.length) +
                                                  40,
                                              height: (MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      playersAlive.length) +
                                                  40,
                                              child: InkWell(
                                                onTap: () async { //if cop pick player
                                                  await FirebaseFirestore //check on firebase if cop was right
                                                      .instance
                                                      .collection('Games')
                                                      .doc(currentGame.gameId)
                                                      .collection('Players')
                                                      .where('playerName',
                                                          isEqualTo: player[
                                                              'playerName'])
                                                      .limit(1)
                                                      .get()
                                                      .then((value) => {
                                                            if (value.docs[0]
                                                                    ['role'] ==
                                                                'killer')
                                                              copRight = true
                                                          });
                                                  if (!doctorSucceed) { //check if doctor was succeed or not
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('Games')
                                                        .doc(currentGame.gameId)
                                                        .collection('Players')
                                                        .where('playerName',
                                                            isEqualTo:
                                                                killerPick)
                                                        .limit(1)
                                                        .get()
                                                        .then((value) { //if doctor not succeed - kill the player on firebase
                                                      (value.docs[0])
                                                          .reference
                                                          .update(
                                                              {'killed': true});
                                                      if (value.docs[0]
                                                              ['role'] ==
                                                          'doctor')
                                                        doctorIsDead = true;
                                                      else if (value.docs[0]
                                                              ['role'] ==
                                                          'cop')
                                                        copIsDead = true;
                                                      else if (value.docs[0]
                                                              ['role'] ==
                                                          'killer')
                                                        numOfKillersLeft--;
                                                      numOfPlayersLeft--; //reducing number of players left
                                                    });
                                                  }
                                                  setState(() {
                                                    copRight =
                                                        copRight ? true : false;
                                                  });
                                                  setState(() {
                                                    picked = true;
                                                  });
                                                  Future.delayed(
                                                      Duration(seconds: 2),
                                                      () => {
                                                            FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                    'Games')
                                                                .doc(currentGame
                                                                    .gameId)
                                                                .update(
                                                                    {'turn': 1})
                                                          });
                                                },
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          100),
                                                  child: Container(
                                                      decoration: (player[
                                                                  'avatar'] !=
                                                              null)
                                                          ? new BoxDecoration(
                                                              color: Colors
                                                                  .brown,
                                                              image:
                                                                  new DecorationImage(
                                                                image: new AssetImage(
                                                                    "lib/assets/avatars/${player['avatar'] + 1}.png"),
                                                                fit:
                                                                    BoxFit.fill,
                                                              ))
                                                          : BoxDecoration(
                                                              color:
                                                                  Colors.brown),
                                                      child: Center(
                                                          child: Text(
                                                              player[
                                                                  'playerName'],
                                                              style: TextStyle(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .black,
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)))),
                                                ),
                                              ))
                                          : KilledCircle(
                                              name: player['playerName'],
                                              avatar: player['avatar'],
                                              numOfP: playersAlive.length,
                                            );
                                    }
                                  }).toList());
                            }
                          }
                        }))
                : Positioned( //right or wrong text for the cop
                    bottom: MediaQuery.of(context).size.height * 0.3,
                    child: copRight
                        ? Text("צדקת",
                            style: TextStyle(color: Colors.green, fontSize: 30))
                        : Text("טעית",
                            style: TextStyle(color: Colors.red, fontSize: 30)),
                  )
            : Container()
      ],
    );
  }
}
