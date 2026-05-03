import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/search_session.dart';
import '../services/api_service.dart';
import '../utils/location_utils.dart';

class SearchProvider extends ChangeNotifier {
  final TextEditingController promptCtrl = TextEditingController();

  final List<SearchSession> sessions = [];
  final Map<String, Map<String, dynamic>> _searchCache = {};

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

  String _buildCacheKey({
    required String prompt,
    required String location,
    required double minPrice,
    required double maxPrice,
  }) {
    return '${prompt.trim().toLowerCase()}|$location|${minPrice.round()}|${maxPrice.round()}';
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
    } catch (e) {
      debugPrint('⚠️ _init error: $e');

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

      final aiResult = data['aiResult'];
      final session = SearchSession(
        id: (data['id'] ?? doc.id).toString(),
        title: (data['title'] ?? 'New search').toString(),
        prompt: (data['prompt'] ?? '').toString(),
        aiResult: aiResult is Map ? Map<String, dynamic>.from(aiResult) : null,
        aiError: data['aiError']?.toString(),
        location: location,
        city: city,
        priceRange: RangeValues(
          ((data['priceStart'] ?? 1) as num).toDouble(),
          ((data['priceEnd'] ?? 500) as num).toDouble(),
        ),
      );

      sessions.add(session);

      if (session.aiResult != null) {
        final cacheKey = _buildCacheKey(
          prompt: session.prompt,
          location: session.location,
          minPrice: session.priceRange.start,
          maxPrice: session.priceRange.end,
        );
        _searchCache[cacheKey] = Map<String, dynamic>.from(session.aiResult!);
      }
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
  debugPrint('🔥 SAVE FUNCTION TRIGGERED');

  final user = FirebaseAuth.instance.currentUser;
  debugPrint('👤 Current user: ${user?.uid}');
  debugPrint('📦 Product received: $product');

  final uid = _uid;
  if (uid == null) {
    throw Exception('User not logged in');
  }

  final cleanedProduct = <String, dynamic>{
    'name': product['name']?.toString() ?? 'Unknown product',
    'price': product['price'] is num ? product['price'] : null,
    'store': product['store']?.toString() ?? 'Unknown store',
    'rating': product['rating'] is num ? product['rating'] : null,
    'image': product['image']?.toString() ?? '',
    'url': product['url']?.toString() ?? '',
    'reason': product['reason']?.toString() ?? '',
    'savedAt': FieldValue.serverTimestamp(),
  };

  debugPrint('💾 Saving favorite for user: $uid');
  debugPrint('💾 Cleaned product: $cleanedProduct');

  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('favorites')
      .add(cleanedProduct);

  debugPrint('✅ Favorite saved');
}
  Future<void> createNewSession() async {
    final newSession = _buildDefaultSession();

    sessions.insert(0, newSession);
    selectedIndex = 0;
    promptCtrl.text = newSession.prompt;
    isLoading = false;
    notifyListeners();

    try {
      await _createSessionInFirestore(newSession);
    } catch (e) {
      debugPrint('⚠️ createNewSession firestore error: $e');
    }
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

    try {
      await _updateSessionInFirestore(currentSession);
    } catch (e) {
      debugPrint('⚠️ updateLocation firestore error: $e');
    }
  }

  Future<void> updateCity(String value) async {
    final cities =
        LocationUtils.countryCities[currentSession.location] ?? ['Accra'];

    currentSession.city = cities.contains(value) ? value : cities.first;
    notifyListeners();

    try {
      await _updateSessionInFirestore(currentSession);
    } catch (e) {
      debugPrint('⚠️ updateCity firestore error: $e');
    }
  }

  Future<void> updatePriceRange(RangeValues value) async {
    currentSession.priceRange = value;
    notifyListeners();

    try {
      await _updateSessionInFirestore(currentSession);
    } catch (e) {
      debugPrint('⚠️ updatePriceRange firestore error: $e');
    }
  }

  Future<void> deleteSession(int index) async {
    if (index < 0 || index >= sessions.length) return;
    if (sessions.length == 1) return;

    final uid = _uid;
    final sessionToDelete = sessions[index];

    sessions.removeAt(index);

    if (selectedIndex >= sessions.length) {
      selectedIndex = sessions.length - 1;
    } else if (selectedIndex > index) {
      selectedIndex -= 1;
    } else if (selectedIndex == index) {
      selectedIndex = 0;
    }

    promptCtrl.text = sessions[selectedIndex].prompt;
    notifyListeners();

    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('sessions')
            .doc(sessionToDelete.id)
            .delete();
      } catch (e) {
        debugPrint('⚠️ deleteSession firestore error: $e');
      }
    }
  }

  Future<void> submitPrompt() async {
    final text = promptCtrl.text.trim();
    if (text.isEmpty || isLoading) return;

    final session = currentSession;

    debugPrint('🚀 submitPrompt started');
    debugPrint('📝 Prompt: $text');

    final cacheKey = _buildCacheKey(
      prompt: text,
      location: session.location,
      minPrice: session.priceRange.start,
      maxPrice: session.priceRange.end,
    );

    if (_searchCache.containsKey(cacheKey)) {
      debugPrint('⚡ Loaded result from cache');

      session.prompt = text;
      session.aiResult = Map<String, dynamic>.from(_searchCache[cacheKey]!);
      session.aiError = null;

      if (session.title == 'New search') {
        session.title = text.length > 28 ? '${text.substring(0, 28)}...' : text;
      }

      promptCtrl.text = text;
      notifyListeners();
      unawaited(_safeUpdateSession(session));
      return;
    }

    session.prompt = text;
    session.aiResult = null;
    session.aiError = null;
    isLoading = true;

    if (session.title == 'New search') {
      session.title = text.length > 28 ? '${text.substring(0, 28)}...' : text;
    }

    notifyListeners();

    unawaited(_safeUpdateSession(session));
    unawaited(_safeLogAnalytics(text));

    try {
      debugPrint('📡 Calling API...');

      final response = await ApiService.getRecommendation(
        text,
        location: session.location,
        minPrice: session.priceRange.start,
        maxPrice: session.priceRange.end,
      ).timeout(const Duration(seconds: 35));

      debugPrint('✅ Raw API response: $response');

      final dynamic resultData = response['result'] ?? response;

      if (resultData is Map) {
        final cleanResult = Map<String, dynamic>.from(resultData);
        session.aiResult = cleanResult;
        session.aiError = null;
        _searchCache[cacheKey] = cleanResult;
      } else {
        session.aiResult = null;
        session.aiError = 'Invalid response format from backend';
      }
    } on TimeoutException {
      session.aiResult = null;
      session.aiError =
          'Request timed out. Check backend server or internet connection.';
      debugPrint('❌ API timeout');
    } catch (e) {
      session.aiResult = null;
      session.aiError = e.toString().replaceFirst('Exception: ', '');
      debugPrint('❌ submitPrompt error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
      await _safeUpdateSession(session);
      debugPrint('✅ submitPrompt finished');
    }
  }

  Future<void> _safeUpdateSession(SearchSession session) async {
    try {
      await _updateSessionInFirestore(session);
    } catch (e) {
      debugPrint('⚠️ _safeUpdateSession error: $e');
    }
  }

  Future<void> _safeLogAnalytics(String prompt) async {
    try {
      await _logSearchAnalytics(prompt);
    } catch (e) {
      debugPrint('⚠️ _safeLogAnalytics error: $e');
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