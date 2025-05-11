// main.dart
import 'package:flutter/material.dart';
import 'package:scouting_shifts_creater/matches_tab.dart';
import 'package:scouting_shifts_creater/schedule_tab.dart';
import 'package:scouting_shifts_creater/scouts_tab.dart';

void main() {
  runApp(const ScoutShiftCreatorApp());
}

class ScoutShiftCreatorApp extends StatelessWidget {
  const ScoutShiftCreatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Scout Shift Creator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ScoutShiftCreator(),
    );
  }
}

// Model classes
class Scout {
  String id;
  String name;
  List<String> unavailableMatches;
  List<String> incompatibleScouts;

  Scout({
    required this.id,
    required this.name,
    this.unavailableMatches = const [],
    this.incompatibleScouts = const [],
  });
}

class Match {
  String id;
  String name;
  String type;

  Match({required this.id, required this.name, this.type = 'Quals'});
}

class ScoutShiftCreator extends StatefulWidget {
  const ScoutShiftCreator({super.key});

  @override
  ScoutShiftCreatorState createState() => ScoutShiftCreatorState();
}

class ScoutShiftCreatorState extends State<ScoutShiftCreator> {
  List<Scout> scouts = [];
  List<Match> matches = [];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scout Shift Creator'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Scouts'),
              Tab(icon: Icon(Icons.event), text: 'Matches'),
              Tab(icon: Icon(Icons.calendar_today), text: 'Schedule'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ScoutsTab(
              scouts: scouts,
              matches: matches,
              onScoutsChanged: (updatedScouts) {
                setState(() {
                  scouts = updatedScouts;
                });
              },
            ),
            MatchesTab(
              matches: matches,
              onMatchesChanged: (updatedMatches) {
                setState(() {
                  matches = updatedMatches;
                });
              },
            ),
            ScheduleTab(scouts: scouts, matches: matches),
          ],
        ),
      ),
    );
  }
}
