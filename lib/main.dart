import 'dart:convert';
//import 'package:ping_discover_network/ping_discover_network.dart';
//import 'package:wifi/wifi.dart';
//import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:look_at_me/after_layout.dart';
import 'package:look_at_me/connection.dart';
import 'package:look_at_me/caching.dart';
import 'package:look_at_me/web_view.dart';
import 'package:look_at_me/model/RadioModel.dart';
import 'package:look_at_me/constant/Constant.dart';
import 'package:look_at_me/localization/localizations.dart';


void main() => runApp(new LookAtMe());

class LookAtMe extends StatefulWidget {

  static void setLocale(BuildContext context, Locale newLocale) async {
    print('setLocale()');
    _LookAtMeState state = context.ancestorStateOfType(TypeMatcher<_LookAtMeState>());

    state.setState(() {
      state.locale = newLocale;
    });
  }

  @override
  _LookAtMeState createState() => new _LookAtMeState();
}

class _LookAtMeState extends State<LookAtMe> {

  Locale locale;
  bool localeLoaded = false;

  @override
  void initState() {
    super.initState();
    print('initState()');

    this._fetchLocale().then((locale) {
      setState(() {
        this.localeLoaded = true;
        this.locale = locale;
      });
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    if (this.localeLoaded == false) {
      return CircularProgressIndicator();
    } else {
      return new MaterialApp(
        title: 'LookAtMe app',
        theme: new ThemeData(
          primarySwatch: Colors.blue,
        ),
        localizationsDelegates: [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('en', ''), // English
          const Locale('tr', ''), // Turkish
          const Locale('hi', ''), // Turkish
        ],
        locale: locale,
        home: new LookAtMeHome(title: 'LookAtMe app'),
      );
    }
  }

  _fetchLocale() async {
    var prefs = await SharedPreferences.getInstance();

    if (prefs.getString('languageCode') == null) {
      return null;
    }

    print('_fetchLocale():' +
        (prefs.getString('languageCode') +
            ':' +
            prefs.getString('countryCode')));

    return Locale(
        prefs.getString('languageCode'), prefs.getString('countryCode'));
  }

}

class LookAtMeHome extends StatefulWidget {
  LookAtMeHome({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _LookAtMeHomeState createState() => new _LookAtMeHomeState();
}

class _LookAtMeHomeState extends State<LookAtMeHome>
    with AfterLayoutMixin<LookAtMeHome> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  List<RadioModel> _langList = new List<RadioModel>();
  int _index=0;

  final idTextController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _initLanguage();

  }

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
        body: new Container(
            child: new Column(
              children: <Widget>[
                _buildMainWidget(),
                _buildLanguageWidget(),
              ],
            )),
        backgroundColor: Colors.black);
  }

  Widget _buildMainWidget() {
    return new Container(
        margin: const EdgeInsets.only(top: 200),

        child: new Padding(
            padding: const EdgeInsets.all(52.0),
            child: new Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new TextField(
                    style: new TextStyle(color: Colors.white),
                    decoration: new InputDecoration.collapsed(
                      hintText: AppLocalizations.of(context).text('LookAtMe Device ID/Name'),
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
                            if (idTextController.text.isNotEmpty) {
//                                    print(idTextController.text);
                              removeCacheData('id');
                              setCacheData('id', idTextController.text);
                              foundAndConnectDevice(context, idTextController.text);
                            } else {
                              print("empty");
                            }
                          },
                          color: Colors.blueGrey,
                          label: Text(AppLocalizations.of(context).text('Connect')),
                          icon: Icon(Icons.check_circle),
                        ),
                      )
                    ],
                  )
                ]))
    );
  }

  Widget _buildLanguageWidget() {
    return new Flexible(
      child: Container(
//        constraints: BoxConstraints(minHeight: 100, maxHeight: 200),
        padding: EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 4.0),
        margin: EdgeInsets.only(left: 4.0, right: 4.0, top: 250),
        color: Colors.grey[100],
        child: ListView.builder(
          itemCount: _langList.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (BuildContext context, int index) {
            return new InkWell(
              splashColor: Colors.blueAccent,
              onTap: () {
                setState(() {
                  _langList.forEach((element) => element.isSelected = false);
                  _langList[index].isSelected = true;
                  _index = index;
                  _handleRadioValueChanged();
                });
              },
              child: new RadioItem(_langList[index]),
            );
          },
        ),
      ),
    );
  }

  @override
  void afterFirstLayout(BuildContext context) {
    if (idTextController.text.isNotEmpty) {
//      foundAndConnectDevice(context);
    }
  }

  List<RadioModel> _getLangList() {
    if(_index==0) {
      _langList.add(new RadioModel(true, 'English'));
      _langList.add(new RadioModel(false, 'Türkçe'));
      _langList.add(new RadioModel(false, 'हिंदी'));
    } else if(_index==1) {
      _langList.add(new RadioModel(false, 'English'));
      _langList.add(new RadioModel(true, 'Türkçe'));
      _langList.add(new RadioModel(false, 'हिंदी'));
    } else if(_index==1) {
      _langList.add(new RadioModel(false, 'English'));
      _langList.add(new RadioModel(false, 'Türkçe'));
      _langList.add(new RadioModel(true, 'हिंदी'));
    }

    return _langList;
  }

  Future<String> _getLanguageCode() async {
    var prefs = await SharedPreferences.getInstance();
    if (prefs.getString('languageCode') == null) {
      return null;
    }
    print('_fetchLocale():' + prefs.getString('languageCode'));
    return prefs.getString('languageCode');
  }

  void _initLanguage() async {
    Future<String> status = _getLanguageCode();
    status.then((result) {
      if (result != null && result.compareTo('en') == 0) {
        setState(() {
          _index = 0;
        });
      }
      if (result != null && result.compareTo('hi') == 0) {
        setState(() {
          _index = 1;
        });
      }
      if (result != null && result.compareTo('tr') == 0) {
        setState(() {
          _index = 2;
        });
      } else {
        setState(() {
          _index = 0;
        });
      }
      print("INDEX: $_index");

      _setupLangList();
    });
  }

  void _setupLangList() {
    setState(() {
      _langList.add(new RadioModel(_index==0?true:false, 'English'));
      _langList.add(new RadioModel(_index==1?true:false, 'हिंदी'));
      _langList.add(new RadioModel(_index==2?true:false, 'Türkçe'));
    });
  }

  void _updateLocale(String lang, String country) async {
    print(lang + ':' + country);

    var prefs = await SharedPreferences.getInstance();
    prefs.setString('languageCode', lang);
    prefs.setString('countryCode', country);

    LookAtMe.setLocale(context, Locale(lang, country));
  }

  void _handleRadioValueChanged() {
    print("SELCET_VALUE: " + _index.toString());
    setState(() {
      switch (_index) {
        case 0:
          print("English");
          _updateLocale('en', '');
          break;
        case 1:
          print("Hindi");
          _updateLocale('hi', '');
          break;
        case 2:
          print("Turkish");
          _updateLocale('tr', '');
          break;
      }
    });
  }

}

class RadioItem extends StatelessWidget {
  final RadioModel _item;

  RadioItem(this._item);

  @override
  Widget build(BuildContext context) {
    return new Container(
      padding: EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 4.0),
      margin: EdgeInsets.only(left: 4.0, right: 4.0),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(left: 4.0, right: 4.0),
            child: new Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                new Container(
                  width: 60.0,
                  height: 4.0,
                  decoration: new BoxDecoration(
                    color: _item.isSelected
                        ? Colors.redAccent
                        : Colors.transparent,
                    border: new Border.all(
                        width: 1.0,
                        color: _item.isSelected
                            ? Colors.redAccent
                            : Colors.transparent),
                    borderRadius:
                    const BorderRadius.all(const Radius.circular(2.0)),
                  ),
                ),
                new Container(
                  margin: new EdgeInsets.only(top: 8.0),
                  child: new Text(
                    _item.title,
                    style: TextStyle(
                      color:
                      _item.isSelected ? Colors.redAccent : Colors.black54,
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}