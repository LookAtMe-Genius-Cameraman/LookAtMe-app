library look_at_me.back_button_globals;
import 'dart:convert';

import 'package:http/http.dart';

import 'connection.dart';

bool deviceConnected = false;

setConnectedStatus(bool isConnected) {

  deviceConnected = isConnected;
}

bool myInterceptor(bool stopDefaultButtonEvent) {
  print("back button pressed."); // Do some stuff.

  if (deviceConnected) {
    disconnectFromDevice(deviceIpAddress, devicePort);
  } else {}
  return false; // If true returns, button's previous events become disable.
}

disconnectFromDevice(ipAddress, port) async {
  // set up DELETE request arguments

  String url = 'http://' + ipAddress + ':' + port.toString() + '/api/access';
  Map<String, String> headers = {
    "Content-type": "application/json; charset=UTF-8"
  };
  Response response = await delete(url,
      headers: headers); // check the status code for the result
  int statusCode = response
      .statusCode; // this API passes back the id of the new item added to the body
  String responseData = response.body;
  var result = json.decode(responseData);
  if (result["status"] == "OK") {
    print("disconnected from device");
  }
}