import 'package:flutter/material.dart';

class Loading extends StatelessWidget {
  const Loading({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xff2B2C26),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "lib/assets/loading.gif",
            ),
            Container(
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey,
                color: Colors.grey[800],
              ),
              width: MediaQuery.of(context).size.width*0.4,
            )
          ],
        ),
      ),
    );
  }
}
