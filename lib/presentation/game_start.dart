import 'package:circle_list/circle_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:town_game/core/current_game.dart';
import 'package:town_game/core/di.dart';
import 'package:town_game/presentation/game.dart';
import 'package:town_game/widgets/timer.dart';

bool copIsDead = false;
bool doctorIsDead = false;

class GameStart extends StatefulWidget {
  GameStart({Key key}) : super(key: key);

  @override
  _GameStartState createState() => _GameStartState();
}

final CurrentGame currentGame = getIt();
CollectionReference players;

class _GameStartState extends State<GameStart> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    FlameAudio.bgm.stop();
    DocumentReference games =
        FirebaseFirestore.instance.collection('Games').doc(currentGame.gameId);
    players = games.collection('Players');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: players
            .where('playerName', isEqualTo: currentUser.name)
            .limit(1)
            .get(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else {
            currentUser.role = snapshot.data.docs[0]['role'];
            return Scaffold(
                extendBodyBehindAppBar: true,
                appBar: AppBar(
                    // backgroundColor: Colors.white70,
                    leadingWidth: 80,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                          height: 50,
                          width: 50,
                          child: FlipCard(
                            back: Container(
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
                                        : currentUser.role + '\n♣',
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
                body: StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection("Games")
                            .doc(currentGame.gameId)
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
                              var turn = dataSnapshot.data['turn'];
                              switch (turn) {
                                case 1:
                                  return Day();
                                  break;
                                case 2:
                                  return Kill();
                                  break;
                                case 3:
                                  if (!doctorIsDead)
                                    return Heal();
                                  else {
                                    changeturn();
                                  }
                                  break;
                                case 4:
                                  if (!copIsDead)
                                    return Investigate();
                                  else {
                                    changetoDay();
                                  }
                                  break;
                              }
                            }
                          }
                        }) ??
                    Container());
          }
        });
  }

  Future<void> changeturn() async {
    await FirebaseFirestore.instance
        .collection('Games')
        .doc(currentGame.gameId)
        .update({'turn': 4});
  }

  Future<void> changetoDay() async {
    await FirebaseFirestore.instance
        .collection('Games')
        .doc(currentGame.gameId)
        .update({'turn': 1});
  }
}

class Day extends StatefulWidget {
  const Day({Key key}) : super(key: key);

  @override
  _DayState createState() => _DayState();
}

class _DayState extends State<Day> with TickerProviderStateMixin {
  AssetImage image;
  AnimationController _controller;
  int levelClock = (currentGame.clockMinutes) * 60;
  bool isTimer = false;
  bool timerFinish = false;

  @override
  void initState() {
    super.initState();
    image = AssetImage("lib/assets/nighttoday.gif");
    //print('${widget.asset} initState');
    //    super.initState();

    Future.delayed(Duration(seconds: 4), () {
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
    //print('${widget.asset} dispose');
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
                    begin: levelClock, // THIS IS A USER ENTERED NUMBER
                    end: 0,
                  ).animate(_controller),
                )
              : Container(),
        ),
        isTimer && currentGame.isAdmin
            ? Positioned(
                bottom: MediaQuery.of(context).size.height * 0.10,
                child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("Games")
                        .doc(currentGame.gameId)
                        .collection('Players')
                        .where('killed', isEqualTo: false)
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
                                  .map<Widget>((DocumentSnapshot player) {
                                return new Container(
                                    width: 60,
                                    height: 60,
                                    child: InkWell(
                                      onTap: () async {
                                        await FirebaseFirestore.instance
                                            .collection('Games')
                                            .doc(currentGame.gameId)
                                            .collection('Players')
                                            .where('playerName',
                                                isEqualTo: killerPick)
                                            .limit(1)
                                            .get()
                                            .then((value) {
                                          (value.docs[0])
                                              .reference
                                              .update({'killed': true});
                                          if (value.docs[0]['role'] == 'doctor')
                                            doctorIsDead = true;
                                          else if (value.docs[0]['role'] ==
                                              'cop') copIsDead = true;
                                        });
                                        changeturn();
                                      },
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        child: Container(
                                            color: Colors.brown,
                                            child: Center(
                                                child: Text(
                                                    player['playerName'],
                                                    style: TextStyle(
                                                        color: Colors.white60,
                                                        fontWeight:
                                                            FontWeight.bold)))),
                                      ),
                                    ));
                              }).toList());
                        }
                      }
                    }))
            : Container(),
        isTimer && currentGame.isAdmin
            ? Positioned(
                bottom: MediaQuery.of(context).size.height * 0.05,
                child: FloatingActionButton(
                  elevation: 5,
                  backgroundColor: Colors.deepOrange,
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
        isKiller
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
                child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("Games")
                        .doc(currentGame.gameId)
                        .collection('Players')
                        .where('killed', isEqualTo: false)
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
                                  .map<Widget>((DocumentSnapshot player) {
                                return new Container(
                                    width: 60,
                                    height: 60,
                                    child: InkWell(
                                      onTap: () async {
                                        await FirebaseFirestore.instance
                                            .collection('Games')
                                            .doc(currentGame.gameId)
                                            .update({
                                          'killerPick': player['playerName']
                                        });
                                        await FirebaseFirestore.instance
                                            .collection('Games')
                                            .doc(currentGame.gameId)
                                            .update({'turn': 3});
                                      },
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        child: Container(
                                            color: Colors.brown,
                                            child: Center(
                                                child: Text(
                                                    player['playerName'],
                                                    style: TextStyle(
                                                        color: Colors.white60,
                                                        fontWeight:
                                                            FontWeight.bold)))),
                                      ),
                                    ));
                              }).toList());
                        }
                      }
                    }))
            : Container()
      ],
    );
  }
}

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
        .then((value) => killerPick = value['killerPick']);
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
        isDoctor
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
                child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("Games")
                        .doc(currentGame.gameId)
                        .collection('Players')
                        .where('killed', isEqualTo: false)
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
                                  .map<Widget>((DocumentSnapshot player) {
                                return new Container(
                                    width: 60,
                                    height: 60,
                                    child: InkWell(
                                      onTap: () async {
                                        await FirebaseFirestore.instance
                                            .collection('Games')
                                            .doc(currentGame.gameId)
                                            .get()
                                            .then((snap) {
                                          if (snap['killerPick'] ==
                                              player['playerName']) {
                                            setState(() {
                                              doctorSucceed = true;
                                              killerPick = snap['killerPick'];
                                            });
                                          }
                                        });

                                        await FirebaseFirestore.instance
                                            .collection('Games')
                                            .doc(currentGame.gameId)
                                            .update({
                                          'turn': 4,
                                          'doctorSucceed': doctorSucceed
                                        });
                                      },
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        child: Container(
                                            color: Colors.brown,
                                            child: Center(
                                                child: Text(
                                                    player['playerName'],
                                                    style: TextStyle(
                                                        color: Colors.white60,
                                                        fontWeight:
                                                            FontWeight.bold)))),
                                      ),
                                    ));
                              }).toList());
                        }
                      }
                    }))
            : Container()
      ],
    );
  }
}

class Investigate extends StatefulWidget {
  const Investigate({Key key}) : super(key: key);

  @override
  _InvestigateState createState() => _InvestigateState();
}

bool isCop;
bool copRight;
Color colorPick;

class _InvestigateState extends State<Investigate> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isCop = currentUser.role == 'cop';
    copRight = false;
    colorPick = Colors.brown;
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
            ? Positioned(
                bottom: MediaQuery.of(context).size.height * 0.10,
                child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("Games")
                        .doc(currentGame.gameId)
                        .collection('Players')
                        .where('killed', isEqualTo: false)
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
                                  .map<Widget>((DocumentSnapshot player) {
                                return new Container(
                                    width: 60,
                                    height: 60,
                                    child: InkWell(
                                      onTap: () async {
                                        await FirebaseFirestore.instance
                                            .collection('Games')
                                            .doc(currentGame.gameId)
                                            .collection('Players')
                                            .where('playerName',
                                                isEqualTo: player['playerName'])
                                            .limit(1)
                                            .get()
                                            .then((value) => {
                                                  if (value.docs[0]
                                                      ['role' == 'killer'])
                                                    setState(() {
                                                      copRight = true;
                                                    })
                                                });
                                        if (!doctorSucceed) {
                                          await FirebaseFirestore.instance
                                              .collection('Games')
                                              .doc(currentGame.gameId)
                                              .collection('Players')
                                              .where('playerName',
                                                  isEqualTo: killerPick)
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
                                        }
                                        setState(() {
                                          colorPick = copRight
                                              ? Colors.green
                                              : Colors.red;
                                        });
                                        Future.delayed(
                                            Duration(seconds: 2),
                                            () => {
                                                  FirebaseFirestore.instance
                                                      .collection('Games')
                                                      .doc(currentGame.gameId)
                                                      .update({'turn': 1})
                                                });
                                      },
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        child: Container(
                                            color: colorPick,
                                            child: Center(
                                                child: Text(
                                                    player['playerName'],
                                                    style: TextStyle(
                                                        color: Colors.white60,
                                                        fontWeight:
                                                            FontWeight.bold)))),
                                      ),
                                    ));
                              }).toList());
                        }
                      }
                    }))
            : Container()
      ],
    );
  }
}
