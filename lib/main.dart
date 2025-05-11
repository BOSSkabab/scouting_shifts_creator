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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
        ),
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
          title: const Text(
            'Scout Shift Creator',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.indigo,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            indicatorWeight: 3.0,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
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
