import 'package:flutter/material.dart';

class CustomListTile extends StatelessWidget {
  CustomListTile({Key key, this.title}) : super(key: key);

  String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top:8.0),
      child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                color: Colors.white24,
              ),
              color: Colors.black45,
              borderRadius: BorderRadius.all(Radius.circular(20))),
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.05,
          child: Center(child: Text(title, style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 18)))),
    );
  }
}
