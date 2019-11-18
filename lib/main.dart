import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import 'package:look_at_me/after_layout.dart';
import 'package:look_at_me/connection.dart';
import 'package:look_at_me/caching.dart';
import 'package:look_at_me/model/RadioModel.dart';
import 'package:look_at_me/localization/localizations.dart';

void main() => runApp(new LookAtMe());

class LookAtMe extends StatefulWidget {
  static void setLocale(BuildContext context, Locale newLocale) async {
    print('setLocale()');
    _LookAtMeState state =
        context.ancestorStateOfType(TypeMatcher<_LookAtMeState>());

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
      SystemChrome.setEnabledSystemUIOverlays([]);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      return new MaterialApp(
        title: 'LookAtMe app',
        theme: new ThemeData(
          primarySwatch: Colors.blue,
        ),
        localizationsDelegates: [
          AppLocalizationsDelegate(),
          const SpecificLocalizationDelegate(Locale('kp', '')),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('de', ''), // German
          const Locale('en', ''), // English
          const Locale('es', ''), // Spanish
          const Locale('fr', ''), // French
          const Locale('hi', ''), // Hindi
          const Locale('it', ''), // Italian
          const Locale('kp', ''), // Korean
          const Locale('tr', ''), // Turkish
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
  int _index = 0;

  final idTextController = TextEditingController();

  MediaQueryData queryData;

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
    queryData = MediaQuery.of(context);

    return new Scaffold(
        body: new Container(
            margin: const EdgeInsets.only(bottom: 0),
            child: new Column(
//              mainAxisAlignment: MainAxisAlignment.center,

              children: <Widget>[
                _buildMainWidget(),
                new Container(
                  color: Colors.black,
                  height: queryData.size.height - 440,
                ),
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
            child: new Column(children: <Widget>[
              new TextField(
                style: new TextStyle(color: Colors.white),
                decoration: new InputDecoration.collapsed(
                  hintText: AppLocalizations.of(context)
                      .text('LookAtMe Device ID/Name'),
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
                          emptyIdentityAreaAlert(context);
                        }
                      },
                      color: Colors.blueGrey,
                      label: Text(AppLocalizations.of(context).text('Connect')),
                      icon: Icon(Icons.check_circle),
                    ),
                  )
                ],
              )
            ])));
  }

  Widget _buildLanguageWidget() {
    return new Flexible(
      child: Container(
        height: 60,
//        constraints: BoxConstraints(minHeight: 100, maxHeight: 200),
        padding: EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 4.0),
        margin: EdgeInsets.only(left: 4.0, right: 4.0),
        color: Colors.black,
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

  List languageData = [
    ['de', 'Deutsch'],
    ['en', 'English'],
    ['es', 'Español'],
    ['fr', 'Français'],
    ['hi', 'हिंदी'],
    ['it', 'Italiano'],
    ['kp', '한국의'],
    ['tr', 'Türkçe']
  ];

  List<RadioModel> _getLangList() {
    for (var i = 0; i < languageData.length; i++) {
      if (_index == i) {
        _langList.add(new RadioModel(true, languageData[i][1]));
      } else {
        _langList.add(new RadioModel(false, languageData[i][1]));
      }
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
      setState(() {
        _index = 0;
      });
      for (var i = 0; i < languageData.length; i++) {
        if (result != null && result.compareTo(languageData[i][0]) == 0) {
          setState(() {
            _index = i;
          });
        }
      }

      print("INDEX: $_index");

      _setupLangList();
    });
  }

  void _setupLangList() {
    setState(() {
      for (var i = 0; i < languageData.length; i++) {
        _langList.add(
            new RadioModel(_index == i ? true : false, languageData[i][1]));
      }
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
      print(languageData[_index][1]);
      _updateLocale(languageData[_index][0], '');
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
      color: Colors.black,
      child: Row(
        children: <Widget>[
          Container(
            color: Colors.black,
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
                      color: _item.isSelected ? Colors.redAccent : Colors.grey,
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

emptyIdentityAreaAlert(context) {

  var alertStyle = AlertStyle(
    animationType: AnimationType.fromTop,
    isCloseButton: false,
    isOverlayTapDismiss: false,
    animationDuration: Duration(milliseconds: 300),
    backgroundColor: Colors.black,
    alertBorder: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(
        color: Colors.grey,
      ),
    ),
    titleStyle: TextStyle(
      color: Colors.red,
      fontWeight: FontWeight.bold,
      fontSize: 26,
    ),
    descStyle: TextStyle(
      color: Colors.white,
      fontSize: 14,
    ),
  );

  Alert(
    context: context,
    style: alertStyle,
    type: AlertType.warning,
    title: AppLocalizations.of(context).text('ID field can\'t be empty'),
    desc: AppLocalizations.of(context).text('Enter LookAtMe\'s unique \'ID\' or name that you give it.'),
    buttons: [
      DialogButton(
        child: Text(
          AppLocalizations.of(context).text('OK'),
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        onPressed: () => Navigator.pop(context),
        width: 100,
        color: Colors.deepOrangeAccent,
      )
    ],
  ).show();
}
