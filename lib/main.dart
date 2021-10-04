import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

void main() {
  runApp(MyApp());
}

var appHeight, appWidth;

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Dictionary',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _url = "https://owlbot.info/api/v4/dictionary/";
  String _token = "f0e2571beccf80bd8f3ed1b6480f3bad569ed233";
  TextEditingController _controller = TextEditingController();
  var _streamController;
  var _stream;
  var subscription;
  var _debounce;
  bool _loading = false, _connected = false;

  _search() async {
    if (_controller.text == null || _controller.text.length == 0) {
      _streamController.add(null);
      return;
    }
    _streamController.add("waiting");
    Response response = await get(Uri.parse(_url + _controller.text.trim()),
        headers: {"Authorization": "Token " + _token});
    _streamController.add(json.decode(response.body));
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _streamController = StreamController();
    _stream = _streamController.stream;
  }

  @override
  Widget build(BuildContext context) {
    appHeight = MediaQuery.of(context).size.height;
    appWidth = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar: AppBar(
          title: Text("Dictionary"),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(appHeight * 0.070),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 12.0, bottom: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    child: TextFormField(
                      onChanged: (String text) async {
                        var result = await (Connectivity().checkConnectivity());
                        if (result == ConnectivityResult.mobile ||
                            result == ConnectivityResult.wifi) {
                          if (_debounce?.isActive ?? false) _debounce.cancel();
                          _debounce =
                              Timer(const Duration(milliseconds: 1000), () {
                            _search();
                          });
                        } else {
                          showMessage("Check Your Connection");
                        }
                      },
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Search for a word",
                        contentPadding: const EdgeInsets.only(left: 24.0),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    var result = await (Connectivity().checkConnectivity());
                    if (result == ConnectivityResult.mobile ||
                        result == ConnectivityResult.wifi) {
                      _search();
                    } else {
                      showMessage("Check Your Connection");
                    }
                  },
                )
              ],
            ),
          ),
        ),
        body: Container(
          width: appWidth,
          height: appHeight,
          child: Container(
            margin: EdgeInsets.all(8.0),
            child: StreamBuilder(
              stream: _stream,
              builder: (BuildContext ctx, AsyncSnapshot snapshot) {
                if (snapshot.data == null) {
                  return Center(
                    child: Text("Please Enter a Search Word"),
                  );
                }
                if (snapshot.data == "waiting") {
                  return Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                    itemCount: snapshot.data["definitions"].length,
                    itemBuilder: (context, int index) {
                      return ListBody(
                        children: [
                          Container(
                            color: Colors.grey[300],
                            child: ListTile(
                              leading: snapshot.data["definitions"][index]
                                          ["image_url"] ==
                                      null
                                  ? null
                                  : CircleAvatar(
                                      backgroundImage: NetworkImage(
                                          snapshot.data["definitions"][index]
                                              ["image_url"]),
                                    ),
                              title: Text(_controller.text.trim() +
                                  "(" +
                                  snapshot.data["definitions"][index]["type"] +
                                  ")"),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(snapshot.data["definitions"][index]
                                ["definition"]),
                          )
                        ],
                      );
                    });
              },
            ),
          ),
        ));
  }

  Widget showMessage(String message) {
    return Align(
      alignment: FractionalOffset.bottomCenter,
      child: Container(
        color: Colors.black54,
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
