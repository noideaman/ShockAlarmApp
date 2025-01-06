import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shock_alarm_app/services/alarm_list_manager.dart';
import 'package:shock_alarm_app/services/openshock.dart';
import '../components/shocker_item.dart';

class ShockerScreen extends StatefulWidget {
  final AlarmListManager manager;

  const ShockerScreen({Key? key, required this.manager}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ShockerScreenState(manager);

  static startRedeemShareCode(AlarmListManager manager, BuildContext context, Function reloadState) {
    showDialog(context: context, builder: (context) {
      TextEditingController codeController = TextEditingController();
      return AlertDialog(
        title: Text("Redeem share code"),
        content: Column(
          children: <Widget>[
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: "Share code"
              ),
            )
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () {
            Navigator.of(context).pop();
          }, child: Text("Cancel")),
          TextButton(onPressed: () async {
            String code = codeController.text;
            if(code.isEmpty) {
              showDialog(context: context, builder: (context) {
                return AlertDialog(
                  title: Text("Invalid code"),
                  content: Text("The code cannot be empty"),
                  actions: <Widget>[
                    TextButton(onPressed: () {
                      Navigator.of(context).pop();
                    }, child: Text("Ok"))
                  ],
                );
              });
              return;
            }
            String? error = await manager.redeemShareCode(code);
            if(error != null) {
              showDialog(context: context, builder: (context) {
                return AlertDialog(
                  title: Text("Error"),
                  content: Text(error),
                  actions: <Widget>[
                    TextButton(onPressed: () {
                      Navigator.of(context).pop();
                    }, child: Text("Ok"))
                  ],
                );
              });
              return;
            }
            Navigator.of(context).pop();
            reloadState();
          }, child: Text("Redeem"))
        ],
      );
    });
  }

  static startPairShocker(AlarmListManager manager, BuildContext context, Function reloadState) async {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: Text("Loading devices"),
        content: Row(
          children: <Widget>[
            CircularProgressIndicator()
          ],
        )
      );
    });
    List<OpenShockDevice> devices = await manager.getDevices();
    Navigator.of(context).pop();
    Navigator.of(context).pop();
    showDialog(context: context, builder: (context) {
      TextEditingController nameController = TextEditingController();
      // number only
      TextEditingController rfIdController = TextEditingController(text: Random().nextInt(65535).toString());
      String shockerType = "CaiXianlin";
      OpenShockDevice? device;
      return AlertDialog(
        title: Text("Add new shocker"),
        content: Column(
          spacing: 10,
          children: <Widget>[
            DropdownMenu<OpenShockDevice>(
              label: Text("Device"),
              onSelected: (value) {
                device = value;
              },
              dropdownMenuEntries: [
              for(OpenShockDevice device in devices)
                DropdownMenuEntry(label: device.name, value: device),
            ]),
            DropdownMenu<String>(dropdownMenuEntries: [
              DropdownMenuEntry(label: "CaiXianlin", value: "CaiXianlin"),
              DropdownMenuEntry(label: "PetTrainer", value: "PetTrainer"),
              DropdownMenuEntry(label: "Petrainer998DR", value: "Petrainer 998DR"),
            ], onSelected: (value) {
              shockerType = value ?? "CaiXianlin";
            },
            label: Text("Shocker type"),
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Shocker Name"
              ),
            ),
            TextField(
              controller: rfIdController,
              decoration: InputDecoration(
                labelText: "RF ID"
              ),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () {
            Navigator.of(context).pop();
          }, child: Text("Cancel")),
          TextButton(onPressed: () async {
            String name = nameController.text;
            if(name.isEmpty) {
              showDialog(context: context, builder: (context) {
                return AlertDialog(
                  title: Text("Invalid name"),
                  content: Text("The name cannot be empty"),
                  actions: <Widget>[
                    TextButton(onPressed: () {
                      Navigator.of(context).pop();
                    }, child: Text("Ok"))
                  ],
                );
              });
              return;
            }
            int rfId = int.tryParse(rfIdController.text) ?? 0;
            if(rfId < 0 || rfId > 65535) {
              showDialog(context: context, builder: (context) {
                return AlertDialog(
                  title: Text("Invalid RF ID"),
                  content: Text("The RF ID must be a number between 0 and 65535"),
                  actions: <Widget>[
                    TextButton(onPressed: () {
                      Navigator.of(context).pop();
                    }, child: Text("Ok"))
                  ],
                );
              });
              return;
            }
            showDialog(context: context, builder: (context) {
              return AlertDialog(
                title: Text("Adding shocker"),
                content: Row(
                  children: <Widget>[
                    CircularProgressIndicator()
                  ],
                )
              );
            });

            String? error = await manager.addShocker(name, rfId, shockerType, device);
            Navigator.of(context).pop();
            if(error != null) {
              showDialog(context: context, builder: (context) {
                return AlertDialog(
                  title: Text("Error"),
                  content: Text(error),
                  actions: <Widget>[
                    TextButton(onPressed: () {
                      Navigator.of(context).pop();
                    }, child: Text("Ok"))
                  ],
                );
              });
              return;
            }
            manager.updateShockerStore();
            Navigator.of(context).pop();
            showDialog(context: context, builder: (context) {
              return AlertDialog(
                title: Text("Almost done"),
                content: Text("Your shocker was created successfully. To pair it with your hub hold down the on/off button until it beeps a few times. Then press the vibrate button in the app to pair it."),
                actions: <Widget>[
                  TextButton(onPressed: () {
                    Navigator.of(context).pop();
                  }, child: Text("Ok"))
                ],
              );
            });
          }, child: Text("Pair"))
        ],
      );
    });
  }

  static getFloatingActionButton(AlarmListManager manager, BuildContext context, Function reloadState) {
    return FloatingActionButton(onPressed: () {
        showDialog(context: context, builder:(context) {
          if(!manager.hasValidAccount()) {
            return AlertDialog(
              title: Text("You're not logged in"),
              content: Text("Login to OpenShock to add a shocker. To do this visit the settings page."),
              actions: <Widget>[
                TextButton(onPressed: () {
                  Navigator.of(context).pop();
                }, child: Text("Ok"))
              ],
            );
          }
          return AlertDialog(
            title: Text("Add shocker"),
            content: Text("What do you want to do?"),
            actions: <Widget>[
              TextButton(onPressed: () {
                Navigator.of(context).pop();
                startRedeemShareCode(manager, context, reloadState);
              }, child: Text("Redeem share code")),
              TextButton(onPressed: () async {
                await startPairShocker(manager, context, reloadState);
              }, child: Text("Add new shocker")),
              TextButton(onPressed: () {
                Navigator.of(context).pop();
              }, child: Text("Cancel")),
            ],
          );
        },);
      }, child: Icon(Icons.add));
  }
}

class ShockerScreenState extends State<ShockerScreen> {
  final AlarmListManager manager;

  void rebuild() {
    setState(() {});
  }

  ShockerScreenState(this.manager);
  @override
  Widget build(BuildContext context) {
    ThemeData t = Theme.of(context);
    List<Shocker> filteredShockers = manager.shockers.where((shocker) {
      return manager.enabledHubs[shocker.hub] ?? false;
    }).toList();
    // group by hub
    Map<String, List<Shocker>> groupedShockers = {};
    for(Shocker shocker in filteredShockers) {
      if(!groupedShockers.containsKey(shocker.hub)) {
        groupedShockers[shocker.hub] = [];
      }
      groupedShockers[shocker.hub]!.add(shocker);
    }
    List<Widget> shockers = [];
    for(var shocker in groupedShockers.entries) {
      shockers.add(Text(shocker.value[0].hub, style: t.textTheme.headlineSmall, textAlign: TextAlign.start,));
      for(var s in shocker.value) {
        shockers.add(ShockerItem(shocker: s, manager: manager, onRebuild: rebuild, key: ValueKey(s.id + s.paused.toString())));
      }
    }
    return Column(children: [
      Text(
        'All shockers',
        style: t.textTheme.headlineMedium,
      ),
      Wrap(spacing: 5,runAlignment: WrapAlignment.start,children: manager.enabledHubs.keys.map<FilterChip>((hub) {
        return FilterChip(label: Text(hub), onSelected: (bool value) {
          manager.enabledHubs[hub] = value;
          setState(() {
          }
        );}, selected: manager.enabledHubs[hub]!);
      }).toList(),),
      Flexible(
        child: RefreshIndicator(child: ListView(children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
              groupedShockers.isEmpty ? [Text('No shockers found', style: t.textTheme.headlineSmall)] : shockers
            )
          ],), onRefresh: () async {
            await manager.updateShockerStore();
            setState(() {});
          }
        )
      )
    ],);
    
  }
}