import 'package:flutter/material.dart';

class UserProfile {
  final int userId;
  final String goal; // 'bulk' or 'cut'
  final bool hasInjury;
  final String? injuryDetails;
  final String dietPreference;
  final String? allergies;
  final DateTime? birthdate;
  final String bodyType;
  final double currentWeight;
  final double targetWeight;
  final double height;
  final String gender;

  UserProfile({
    required this.userId,
    required this.goal,
    required this.hasInjury,
    this.injuryDetails,
    required this.dietPreference,
    this.allergies,
    this.birthdate,
    required this.bodyType,
    required this.currentWeight,
    required this.targetWeight,
    required this.height,
    required this.gender,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as int,
      goal: json['goal'] as String,
      hasInjury: (json['has_injury'] as int) == 1,
      injuryDetails: json['injury_details'],
      dietPreference: json['diet_preference'] as String,
      allergies: json['allergies'],
      birthdate: json['birthdate'] != null ? DateTime.parse(json['birthdate']) : null,
      bodyType: json['body_type'] as String,
      currentWeight: double.tryParse(json['current_weight']?.toString() ?? '0') ?? 0,
      targetWeight: double.tryParse(json['target_weight']?.toString() ?? '0') ?? 0,
      height: double.tryParse(json['height']?.toString() ?? '0') ?? 0,
      gender: json['gender'] as String,
    );
  }

  bool get isBulking => goal.toLowerCase() == 'bulk' || goal.toLowerCase().contains('muscle');
  bool get isCutting => goal.toLowerCase() == 'cut' || goal.toLowerCase().contains('weight') || goal.toLowerCase().contains('loss');

  int get age {
    if (birthdate == null) return 30;
    return DateTime.now().difference(birthdate!).inDays ~/ 365;
  }

  // Calculate recommended sets based on goal and fitness level
  int get recommendedSets => isBulking ? 4 : 3;

  // Calculate recommended reps based on goal
  int get recommendedReps => isBulking ? 8 : 12;

  // Get target muscles based on goal and body type
  List<String> get targetMuscles {
    if (isBulking) {
      return ['chest', 'back', 'shoulders', 'biceps', 'triceps', 'legs'];
    } else {
      return ['core', 'legs', 'back']; // Focus on large muscle groups for fat loss
    }
  }
}

class ExerciseRecommender {
  static final Map<String, Map<String, dynamic>> _exerciseDatabase = {
    'Dumbbell Curls': {
      'equipment': ['dumbbells'],
      'muscles': ['biceps'],
      'bulk': {'sets': 4, 'reps': 8},
      'cut': {'sets': 3, 'reps': 15},
      'injury_safe': true,
      'injury_restrictions': [], // No specific restrictions
    },
    'Hammer Curls': {
      'equipment': ['dumbbells'],
      'muscles': ['biceps', 'forearms'],
      'bulk': {'sets': 4, 'reps': 8},
      'cut': {'sets': 3, 'reps': 15},
      'injury_safe': true,
      'injury_restrictions': [],
    },
    'Shoulder Press': {
      'equipment': ['dumbbells'],
      'muscles': ['shoulders', 'triceps'],
      'bulk': {'sets': 4, 'reps': 8},
      'cut': {'sets': 3, 'reps': 12},
      'injury_safe': false,
      'injury_restrictions': ['shoulder', 'neck'],
    },
    'Dumbbell Bench Press': {
      'equipment': ['dumbbells', 'bench'],
      'muscles': ['chest', 'triceps', 'shoulders'],
      'bulk': {'sets': 4, 'reps': 8},
      'cut': {'sets': 3, 'reps': 12},
      'injury_safe': false,
      'injury_restrictions': ['shoulder', 'chest'],
    },
    'Dumbbell Rows': {
      'equipment': ['dumbbells', 'bench'],
      'muscles': ['back', 'biceps'],
      'bulk': {'sets': 4, 'reps': 8},
      'cut': {'sets': 3, 'reps': 12},
      'injury_safe': true,
      'injury_restrictions': ['lower back'],
    },
    'Goblet Squats': {
      'equipment': ['dumbbell'],
      'muscles': ['legs', 'core'],
      'bulk': {'sets': 4, 'reps': 8},
      'cut': {'sets': 3, 'reps': 15},
      'injury_safe': false,
      'injury_restrictions': ['knee', 'back'],
    },
    'Plank': {
      'equipment': [],
      'muscles': ['core'],
      'bulk': {'sets': 3, 'reps': 30}, // seconds for planks
      'cut': {'sets': 4, 'reps': 45},
      'injury_safe': true,
      'injury_restrictions': [],
    },
    'Jumping Jacks': {
      'equipment': [],
      'muscles': ['cardio', 'legs'],
      'bulk': {'sets': 3, 'reps': 30}, // seconds for cardio
      'cut': {'sets': 4, 'reps': 45},
      'injury_safe': false,
      'injury_restrictions': ['knee', 'ankle'],
    },
  };

  static List<Map<String, dynamic>> recommendExercises(UserProfile profile) {
    return _exerciseDatabase.entries.where((exercise) {
      final exData = exercise.value;

      // Filter out exercises that aren't injury-safe
      if (profile.hasInjury) {
        // Check if exercise has specific restrictions that match user's injury
        final injuryDetails = profile.injuryDetails?.toLowerCase() ?? '';
        final hasMatchingRestriction = exData['injury_restrictions'].any((restriction) =>
            injuryDetails.contains(restriction.toLowerCase()));

        if (hasMatchingRestriction || !exData['injury_safe']) {
          return false;
        }
      }

      // Filter for target muscles
      return exData['muscles'].any((muscle) =>
          profile.targetMuscles.contains(muscle));
    }).map((exercise) {
      final exName = exercise.key;
      final exData = exercise.value;

      // Use profile's recommended sets/reps instead of hardcoded values
      var recommendation = {
        'sets': profile.recommendedSets,
        'reps': profile.recommendedReps,
      };

      return {
        'name': exName,
        ...recommendation,
        'muscles_targeted': exData['muscles'],
        'goal_specific': profile.isBulking ? 'Muscle Gain' : 'Fat Loss',
      };
    }).toList();
  }

  static String getWorkoutFocus(UserProfile profile) {
    if (profile.isBulking) {
      return 'Strength & Muscle Building';
    } else {
      return 'Fat Loss & Endurance';
    }
  }
}