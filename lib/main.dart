import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:look_at_me/after_layout.dart';
import 'package:wifi/wifi.dart';
import 'package:ping_discover_network/ping_discover_network.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:look_at_me/localization/app_translations.dart';
import 'package:look_at_me/localization/app_translations_delegate.dart';
import 'package:look_at_me/localization/application.dart';

void main() => runApp(LookAtMe());

class LookAtMe extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
//      localizationsDelegates: [
//        // ... app-specific localization delegate[s] here
//        GlobalMaterialLocalizations.delegate,
//        GlobalWidgetsLocalizations.delegate,
//        GlobalCupertinoLocalizations.delegate,
//      ],
//      supportedLocales: [
//        const Locale('en'), // English
//        const Locale('tr'), // Turkish
//        const Locale.fromSubtags(languageCode: 'zh'), // Chinese *See Advanced Locales below*
//        // ... other locales the app supports
//      ],
      title: 'LookAtMe app',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LookAtMeHome(title: 'LookAtMe app'),
    );
  }
}

class LookAtMeHome extends StatefulWidget {
  LookAtMeHome({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _LookAtMeHomeState createState() => _LookAtMeHomeState();
}

class _LookAtMeHomeState extends State<LookAtMeHome>
    with AfterLayoutMixin<LookAtMeHome> {

//  AppTranslationsDelegate _newLocaleDelegate;

  static final List<String> languagesList = application.supportedLanguages;
  static final List<String> languageCodesList = application.supportedLanguagesCodes;

  final Map<dynamic, dynamic> languagesMap = {
    languagesList[0]: languageCodesList[0],
    languagesList[1]: languageCodesList[1],
  };

  @override
  void initState() {
    super.initState();
//    _newLocaleDelegate = AppTranslationsDelegate(newLocale: null);
    application.onLocaleChanged = onLocaleChange;
    onLocaleChange(Locale(languagesMap["Türkçe"]));
    print(application.supportedLanguages[0] + "Language...");
  }

  void onLocaleChange(Locale locale) {
    setState(() {
//      _newLocaleDelegate = AppTranslationsDelegate(newLocale: locale);
      AppTranslations.load(locale);
    });
  }

  getCachedData(key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? 0;
  }

  setCacheData(key, value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  removeCacheData(key) async {
    final prefs = await SharedPreferences.getInstance();

    if (getCachedData(key) != 0) {
     prefs.remove(key);
    }
  }


  foundAndConnectDevice(context) async {
    final String ip = await Wifi.ip;
    print(ip);
    final String subnet = ip.substring(0, ip.lastIndexOf('.'));
    final int port = 5000;

    final stream = NetworkAnalyzer.discover2('192.168.45', port);
    bool isConnected = false;
    while (!isConnected) {
      stream.listen((NetworkAddress addr) {
        if (addr.exists) {
          isConnected = _makePostRequest(addr.ip, port, '/api/access');
        }
      }).onDone(() => print('finish.'));
    }
  }

  _makePostRequest(ipAddress, port, urls) async {
    // set up POST request arguments

    String url = 'http://' + ipAddress + ':' + port.toString() + urls;
    Map<String, String> headers = {
      "Content-type": "application/json; charset=UTF-8"
    };
    String jsonData =
        '{"id": "' + idTextController.text + '"}'; // make POST request
    Response response = await post(url,
        headers: headers,
        body: jsonData); // check the status code for the result
    int statusCode = response
        .statusCode; // this API passes back the id of the new item added to the body
    String responseData = response.body;
    var result = json.decode(responseData);
//    print(result);

    if (result["status"] == "OK") {
      Navigator.of(context)
          .push(MaterialPageRoute<Null>(builder: (BuildContext context) {
            SystemChrome.setEnabledSystemUIOverlays([]);
        return new WebViewWebPage(
            url: 'http://$ipAddress:${port.toString()}$urls?id=${result["data"].toString()}');
      }));
      return true;
    }
    return false;
  }

  final idTextController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    idTextController.dispose();
    String id = getCachedData('id');
    print(id);
    if (id.isNotEmpty) {
      idTextController.text = id;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: new Padding(
            padding: const EdgeInsets.all(52.0),
            child: new Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new TextField(
                    style: new TextStyle(color: Colors.white),
                    decoration: new InputDecoration.collapsed(
                      hintText: AppTranslations.text("LookAtMe Device ID/Name"),
                      hintStyle: new TextStyle(color: Colors.grey),
                    ),
                    controller: idTextController,
                  ),
                  new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      new Container(
                        margin: const EdgeInsets.only(top: 10.0),
                        child: new FlatButton.icon(
                          padding: const EdgeInsets.all(8.0),
                          textColor: Colors.white,
                          onPressed: () {
                                  if(idTextController.text.isNotEmpty) {
//                                    print(idTextController.text);
                                    removeCacheData('id');
                                    setCacheData('id', idTextController.text);
                                    foundAndConnectDevice(context);
                                  }else {
                                    print("empty");
                                  }
                                },
                          color: Colors.blueGrey,
                          label: Text(AppTranslations.text("Connect")),
                          icon: Icon(Icons.check_circle),
                        ),
                      )
                    ],
                  )
                ])),
        backgroundColor: Colors.black);
  }

  @override
  void afterFirstLayout(BuildContext context) {
    if (idTextController.text.isNotEmpty) {
//      foundAndConnectDevice(context);
    }
  }
}

class WebViewWebPage extends StatelessWidget {
  final String url;

  WebViewWebPage({this.url});

  @override
  Widget build(BuildContext context) {
    return WebviewScaffold(
      url: url,
      hidden: true,
      appBar: null,
    );
  }
}
