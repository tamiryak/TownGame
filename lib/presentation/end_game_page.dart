import 'package:flutter/material.dart';

import '../main.dart';

class EndGame extends StatelessWidget {
  const EndGame({Key key, this.won}) : super(key: key);
  final String won;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leadingWidth: 80,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        resizeToAvoidBottomInset: true,
        body: Container(
          //background
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            image: DecorationImage(
                fit: BoxFit.fill, image: AssetImage('lib/assets/town.jpg')),
          ),
          child: Column(
            children: [
              Text(
                "$won הקבוצה המנצח היא",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 35,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height:20),
              Container(
                height: 50.0,
                margin: EdgeInsets.all(10),
                child: RaisedButton(
                  //button for entering to game
                  onPressed: () async {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) => Town()));
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
                        "חזור לדף הראשי",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
