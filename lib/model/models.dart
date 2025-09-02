// This file defines the structure of the data you get from the AI.

class Itinerary {
  final List<DayPlan> days;

  Itinerary({required this.days});

  // This factory constructor parses the main JSON object.
  factory Itinerary.fromJson(Map<String, dynamic> json) {
    var list = json['itinerary'] as List;
    List<DayPlan> daysList = list.map((i) => DayPlan.fromJson(i)).toList();
    return Itinerary(days: daysList);
  }
}

class DayPlan {
  final String day;
  final String title;
  final List<Activity> plan;

  DayPlan({required this.day, required this.title, required this.plan});

  // This factory constructor parses each day's object from the list.
  factory DayPlan.fromJson(Map<String, dynamic> json) {
    var list = json['plan'] as List;
    List<Activity> activityList = list.map((i) => Activity.fromJson(i)).toList();
    return DayPlan(day: json['day'], title: json['title'], plan: activityList);
  }
}

class Activity {
  final String time;
  final String placeName;
  final String description;

  Activity({required this.time, required this.placeName, required this.description});

  // This factory constructor parses each activity object.
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      time: json['time'],
      placeName: json['place_name'],
      description: json['description'],
    );
  }
}
