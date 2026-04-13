import 'package:flutter/material.dart';

class SearchSession {
  final String id;
  String title;
  String prompt;
  Map<String, dynamic>? aiResult;
  String? aiError;
  String location;
  String city;
  RangeValues priceRange;

  SearchSession({
    required this.id,
    required this.title,
    this.prompt = '',
    this.aiResult,
    this.aiError,
    this.location = 'US',
    this.city = 'New York',
    this.priceRange = const RangeValues(1, 500),
  });
}