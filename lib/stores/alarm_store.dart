import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobx/mobx.dart';
import 'package:shock_alarm_app/services/alarm_list_manager.dart';
import 'package:shock_alarm_app/services/openshock.dart';
import '../main.dart';

class Token with Store {
  Token(this.id, this.token, {this.server = "https://api.openshock.app", this.name="", this.isSession = false, this.userId = ""});

  int id;

  String token;
  String server;
  bool isSession = false;
  String name = "";
  String userId = "";

  static Token fromJson(token) {
    return Token(token["id"], token["token"], server: token["server"], name: token["name"] ?? "", isSession: token["isSession"] ?? false, userId: token["userId"] ?? "");
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "token": token, "server": server, "name": name, "isSession": isSession, "userId": userId};
  }
}

class AlarmShocker {
  String shockerId = "";
  String? toneId;
  int intensity = 25;
  int duration = 1000;
  ControlType? type = ControlType.vibrate;
  Shocker? shockerReference;

  bool enabled = false;
  
  Map<String, dynamic> toJson() {
    return {
      "shockerId": shockerId, 
      "toneId": toneId,
      "intensity": intensity,
      "duration": duration,
      "type": type?.index ?? -1,
      "enabled": enabled
    };
  }

  static AlarmShocker fromJson(shocker) {
    return AlarmShocker()
      ..shockerId = shocker["shockerId"]
      ..toneId = shocker["toneId"]
      ..intensity = shocker["intensity"]
      ..duration = shocker["duration"]
      ..type = shocker["type"] == -1 ? null : ControlType.values[shocker["type"]]
      ..enabled = shocker["enabled"];
  }
}

class ObservableAlarmBase with Store {
  int id;
  String name;
  int hour;
  int minute;
  bool monday;
  bool tuesday;
  bool wednesday;
  bool thursday;
  bool friday;
  bool saturday;
  bool sunday;
  bool active;
  List<AlarmShocker> shockers = [];

  ObservableAlarmBase(
      {required this.id,
      required this.name,
      required this.hour,
      required this.minute,
      this.monday = false,
      this.tuesday = false,
      this.wednesday = false,
      this.thursday = false,
      this.friday = false,
      this.saturday = false,
      this.sunday = false,
      required this.active});

  List<bool> get days {
    return [monday, tuesday, wednesday, thursday, friday, saturday, sunday];
  }

  void trigger(AlarmListManager manager, bool disableIfApplicable) {
    // ToDo: show notification
    FlutterLocalNotificationsPlugin().show(id, name,"Your alarm is firing", NotificationDetails(android: AndroidNotificationDetails("alarms", "Alarms", enableVibration: true, priority: Priority.high, importance: Importance.max, actions: [
      AndroidNotificationAction("stop", "Stop alarm", showsUserInterface: true),
      AndroidNotificationAction("detail", "Detail", showsUserInterface: true),
    ])), payload: id.toString());

    var maxDuration = 0;

    for (var shocker in shockers) {
      if (shocker.enabled) {
        if (shocker.duration > maxDuration) {
          maxDuration = shocker.duration;
        }
        // If a shocker is paused the backend will return an error. So we don't need to check if it's paused. Especially as the saved state may not reflect the real paused state.
        manager.sendShock(shocker.type!, shocker.shockerReference!, shocker.intensity, shocker.duration, customName: name);
      }
    }

    // Wait until all shockers have finished
    Future.delayed(Duration(milliseconds: maxDuration), () {
      onAlarmStopped(manager);
    });

    if (disableIfApplicable) {
      if(!shouldSchedulePerWeekday()) {
        active = false;
        manager.saveAlarm(this);
      }
    }

  }

  void onAlarmStopped(AlarmListManager manager, {bool needStop = true}) {
    if(needStop) {
      for (var shocker in shockers) {
        if (shocker.enabled) {
          // Stop all shockers
          manager.sendShock(ControlType.stop, shocker.shockerReference!, shocker.intensity, shocker.duration, customName: name);
        }
      }
    }

    FlutterLocalNotificationsPlugin().show(id, name,"Alarm stopped", NotificationDetails(android: AndroidNotificationDetails("alarms", "Alarms", enableVibration: true, priority: Priority.high, importance: Importance.max)), payload: id.toString());

  }

  // Good enough for debugging for now
  @override
  toString() {
    return "active: $active, name: $name, hour: $hour, minute: $minute, days: $days";
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "hour": hour,
      "minute": minute,
      "monday": monday,
      "tuesday": tuesday,
      "wednesday": wednesday,
      "thursday": thursday,
      "friday": friday,
      "saturday": saturday,
      "sunday": sunday,
      "active": active,
      "shockers": shockers.map((e) => e.toJson()).toList()
    };
  }

  static ObservableAlarmBase fromJson(alarm) {
    ObservableAlarmBase a = ObservableAlarmBase(
      id: alarm["id"],
      name: alarm["name"],
      hour: alarm["hour"],
      minute: alarm["minute"],
      monday: alarm["monday"],
      tuesday: alarm["tuesday"],
      wednesday: alarm["wednesday"],
      thursday: alarm["thursday"],
      friday: alarm["friday"],
      saturday: alarm["saturday"],
      sunday: alarm["sunday"],
      active: alarm["active"]);
    if(alarm["shockers"] != null) {
      a.shockers = (alarm["shockers"] as List).map((e) => AlarmShocker.fromJson(e)).toList();
    }
    return a;
  }

  bool shouldSchedulePerWeekday() {
    return days.any((element) {
      return element == true;
    });
  }

  schedule(AlarmListManager manager) async {
    if (!shouldSchedulePerWeekday()) {
      // Schedule for next occurrance 
      DateTime now = DateTime.now();
      DateTime nextOccurrance = DateTime(now.year, now.month, now.day, hour, minute);
      if (nextOccurrance.isBefore(now)) {
        nextOccurrance = nextOccurrance.add(Duration(days: 1));
      }
      ScaffoldMessenger.of(manager.context!).showSnackBar(SnackBar(content: Text("Scheduled alarm for ${nextOccurrance.toString()}")));
      AndroidAlarmManager.oneShotAt(nextOccurrance, id, alarmCallback, exact: true, wakeup: true);
    }
  }
}