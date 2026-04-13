import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/search_session.dart';
import '../services/api_service.dart';
import '../utils/location_utils.dart';

class SearchProvider extends ChangeNotifier {
  final TextEditingController promptCtrl = TextEditingController();

  final List<SearchSession> sessions = [];
  int selectedIndex = 0;
  bool isLoading = false;
  bool isInitialized = false;

  SearchProvider() {
    _init();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  SearchSession get currentSession {
    if (sessions.isEmpty) {
      final fallback = _buildDefaultSession();
      sessions.add(fallback);
      selectedIndex = 0;
    }

    if (selectedIndex < 0 || selectedIndex >= sessions.length) {
      selectedIndex = 0;
    }

    return sessions[selectedIndex];
  }

  String get currencySymbol =>
      LocationUtils.getCurrencySymbol(currentSession.location);

  List<String> get availableCities =>
      LocationUtils.countryCities[currentSession.location] ?? ['Accra'];

  SearchSession _buildDefaultSession() {
    return SearchSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New search',
      prompt: '',
      aiResult: null,
      aiError: null,
      location: 'GH',
      city: 'Accra',
      priceRange: const RangeValues(1, 500),
    );
  }

  Future<void> _init() async {
    try {
      await loadSessionsFromFirestore();

      if (sessions.isEmpty) {
        final firstSession = _buildDefaultSession();
        sessions.add(firstSession);
        await _createSessionInFirestore(firstSession);
      }

      selectedIndex = 0;
      promptCtrl.text = currentSession.prompt;
    } catch (_) {
      if (sessions.isEmpty) {
        sessions.add(_buildDefaultSession());
      }

      selectedIndex = 0;
      promptCtrl.text = currentSession.prompt;
    } finally {
      isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> loadSessionsFromFirestore() async {
    final uid = _uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .orderBy('updatedAt', descending: true)
        .get();

    sessions.clear();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final location = (data['location'] ?? 'GH').toString();
      final cities = LocationUtils.countryCities[location] ?? ['Accra'];

      String city = (data['city'] ?? 'Accra').toString();
      if (!cities.contains(city)) {
        city = cities.first;
      }

      sessions.add(
        SearchSession(
          id: (data['id'] ?? doc.id).toString(),
          title: (data['title'] ?? 'New search').toString(),
          prompt: (data['prompt'] ?? '').toString(),
          aiResult: data['aiResult'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(data['aiResult'] as Map)
              : null,
          aiError: data['aiError']?.toString(),
          location: location,
          city: city,
          priceRange: RangeValues(
            ((data['priceStart'] ?? 1) as num).toDouble(),
            ((data['priceEnd'] ?? 500) as num).toDouble(),
          ),
        ),
      );
    }
  }

  Future<void> _createSessionInFirestore(SearchSession session) async {
    final uid = _uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(session.id)
        .set({
      'id': session.id,
      'title': session.title,
      'prompt': session.prompt,
      'location': session.location,
      'city': session.city,
      'priceStart': session.priceRange.start,
      'priceEnd': session.priceRange.end,
      'aiResult': session.aiResult,
      'aiError': session.aiError,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateSessionInFirestore(SearchSession session) async {
    final uid = _uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(session.id)
        .set({
      'id': session.id,
      'title': session.title,
      'prompt': session.prompt,
      'location': session.location,
      'city': session.city,
      'priceStart': session.priceRange.start,
      'priceEnd': session.priceRange.end,
      'aiResult': session.aiResult,
      'aiError': session.aiError,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

Future<void> _logSearchAnalytics(String prompt) async {
  final uid = _uid;
  if (uid == null) return;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('analytics')
      .add({
    'prompt': prompt,
    'location': currentSession.location,
    'city': currentSession.city,
    'priceStart': currentSession.priceRange.start,
    'priceEnd': currentSession.priceRange.end,
    'createdAt': FieldValue.serverTimestamp(),
  });
}


Future<void> saveFavoriteProduct(Map<String, dynamic> product) async {
  final uid = _uid;
  if (uid == null) return;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('favorites')
      .add({
    ...product,
    'savedAt': FieldValue.serverTimestamp(),
  });
}


  Future<void> createNewSession() async {
    final newSession = _buildDefaultSession();

    sessions.insert(0, newSession);
    selectedIndex = 0;
    promptCtrl.text = newSession.prompt;
    isLoading = false;
    notifyListeners();

    await _createSessionInFirestore(newSession);
  }

  void selectSession(int index) {
    if (index < 0 || index >= sessions.length) return;

    selectedIndex = index;

    final cities =
        LocationUtils.countryCities[currentSession.location] ?? ['Accra'];

    if (!cities.contains(currentSession.city)) {
      currentSession.city = cities.first;
    }

    promptCtrl.text = currentSession.prompt;
    notifyListeners();
  }

  Future<void> updateLocation(String value) async {
    currentSession.location = value;

    final cities = LocationUtils.countryCities[value] ?? ['Accra'];
    currentSession.city = cities.first;

    notifyListeners();
    await _updateSessionInFirestore(currentSession);
  }

  Future<void> updateCity(String value) async {
    final cities =
        LocationUtils.countryCities[currentSession.location] ?? ['Accra'];

    currentSession.city = cities.contains(value) ? value : cities.first;

    notifyListeners();
    await _updateSessionInFirestore(currentSession);
  }

  Future<void> updatePriceRange(RangeValues value) async {
    currentSession.priceRange = value;
    notifyListeners();
    await _updateSessionInFirestore(currentSession);
  }

  Future<void> submitPrompt() async {
    final text = promptCtrl.text.trim();
    if (text.isEmpty || isLoading) return;

    await _logSearchAnalytics(text);

    currentSession.prompt = text;
    currentSession.aiResult = null;
    currentSession.aiError = null;
    isLoading = true;

    if (currentSession.title == 'New search') {
      currentSession.title =
          text.length > 28 ? '${text.substring(0, 28)}...' : text;
    }

    notifyListeners();
    await _updateSessionInFirestore(currentSession);

    try {
      final response = await ApiService.getRecommendation(
        text,
        location: currentSession.location,
        minPrice: currentSession.priceRange.start,
        maxPrice: currentSession.priceRange.end,
      );

      final result = response['result'];

      if (result is Map<String, dynamic>) {
        currentSession.aiResult = Map<String, dynamic>.from(result);
        currentSession.aiError = null;
      } else {
        currentSession.aiResult = null;
        currentSession.aiError = 'Invalid response format';
      }
    } catch (e) {
      currentSession.aiResult = null;
      currentSession.aiError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
      await _updateSessionInFirestore(currentSession);
    }
  }

  Future<void> retrySearch() async {
    await submitPrompt();
  }

  @override
  void dispose() {
    promptCtrl.dispose();
    super.dispose();
  }
}