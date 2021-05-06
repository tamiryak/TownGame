import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:town_game/core/current_game.dart';
import 'package:town_game/core/current_user.dart';
import 'package:town_game/core/di.dart';
import 'package:town_game/presentation/join_game.dart';
import 'package:town_game/widgets/custom_list_tile.dart';

import 'game_start.dart';

class Game extends StatefulWidget {
  Game({Key key}) : super(key: key);

  @override
  _GameState createState() => _GameState();
}

final CurrentGame currentGame = getIt();
final CurrentUser currentUser = getIt();
int numOfPlayers = 0;
bool isStarting = false;

class _GameState extends State<Game> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isStarting = false;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // backgroundColor: Colors.white70,
        leadingWidth: 80,
        title: Padding(
          padding: const EdgeInsets.only(top: 30.0),
          child: Text( //title
            "רשימת משתתפים",
            style: TextStyle(fontSize: 30),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: FlatButton.icon( //return button
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: Colors.white70),
          label: Text("  "),
        ),
      ),
      body: Column(
        children: [
          StreamBuilder( //stream builder for the current game 
                  stream: FirebaseFirestore.instance
                      .collection("Games")
                      .doc(currentGame.gameId)
                      .snapshots(),
                  builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container();
                      } else {
                        if (snapshot.error != null) {
                          return Container();
                        } else {
                          var turn = snapshot.data['turn']; //return the turn of the game
                          if (turn == 1) { // if player 1 start the game, the turn will change to 1 and the we navigate to the game loop page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => GameStart()), //game loop page
                            );
                          } else
                            return Container();
                        }
                      }
                    
                  }) ??
              Container(),
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              image: DecorationImage( //background
                  fit: BoxFit.fill, image: AssetImage('lib/assets/town.jpg')),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 70.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white24,
                        ),
                        color: Colors.black54,
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: StreamBuilder( //stream builder for all the players registered to the game
                      stream: FirebaseFirestore.instance
                          .collection("Games")
                          .doc(currentGame.gameId)
                          .collection("Players")
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
                            var players = dataSnapshot.data.docs; //get the players list
                            
                            numOfPlayers = players.length;
                            currentGame.numOfPlayers=numOfPlayers;
                            return new ListView(
                                children: players
                                    .map<Widget>((DocumentSnapshot player) { //creating custom list tile for each player
                              return new CustomListTile(
                                title: player["playerName"].toString(),
                              );
                            }).toList());
                          }
                        }
                      },
                    ),
                  ),
                  Padding( //game code of the room written on buttom
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Text(
                      "${currentGame.gameId.substring(0, 6)}" + ":קוד חדר",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                  currentGame.isAdmin //only admin can start the game - only he seeing the button
                      ? Container(
                          height: 50.0,
                          margin: EdgeInsets.all(10),
                          child: RaisedButton(
                            onPressed: () async {
                              isStarting=true;
                              if (numOfPlayers >=
                                  3 * currentGame.numOfKillers) { //can start just if number of players is multiple 3 of the killers (3,9)
                                await startGame(); //start the game on firebase
                              }
                            },
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(80.0)),
                            padding: EdgeInsets.all(0.0),
                            child: Ink(
                              decoration: BoxDecoration( //button style
                                  gradient: (numOfPlayers >=
                                          3 * currentGame.numOfKillers)
                                      ? LinearGradient(
                                          colors: [
                                            Colors.brown,
                                            Color(0xff3b1d1c)
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        )
                                      : LinearGradient(
                                          colors: [Colors.grey, Colors.black38],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                  borderRadius: BorderRadius.circular(30.0)),
                              child: Container(
                                constraints: BoxConstraints(
                                    maxWidth: 250.0, minHeight: 50.0),
                                alignment: Alignment.center,
                                child: Text(
                                  "התחל משחק",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 15),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  //start game on firebase function
  Future<void> startGame() async {
    DocumentReference games =
        FirebaseFirestore.instance.collection('Games').doc(currentGame.gameId); //get the game doc

    CollectionReference players = games.collection('Players'); //get the players collection
    await players.get().then((querySnapshot) {
      //shuffling the players list and dealing the cards by roles to the players
      List<QueryDocumentSnapshot> snap = querySnapshot.docs; 
      snap.shuffle();
      snap[0].reference.update({'role':'cop'});
      snap[1].reference.update({'role':'doctor'});
      for(int i=2;i<2+currentGame.numOfKillers;i++)
      snap[i].reference.update({'role':'killer'});
    });
    //gets the role the player get from the shuffling
    await players.where('playerName',isEqualTo:currentUser.name).limit(1).get().then((querySnapshot) => currentUser.role = querySnapshot.docs[0]['role']);
    //update the game to start
    await games.update({'turn': 1});
  }
}
