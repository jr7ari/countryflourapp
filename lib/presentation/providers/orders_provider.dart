import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/order_model.dart';
import '../../data/models/address_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/auth_repository.dart';

// ─── SharedPreferences keys ───────────────────────────────────────────────────
const _kToken = 'auth_token';
const _kName = 'auth_name';
const _kEmail = 'auth_email';
const _kPhone = 'auth_phone';
const _kPhotoUrl = 'auth_photo_url';

// ─── Repository (token-aware) ─────────────────────────────────────────────────

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final token = ref.watch(authProvider).token;
  return OrderRepository(token: token);
});

// ─── Orders ───────────────────────────────────────────────────────────────────

final ordersProvider = FutureProvider<List<Order>>((ref) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getOrders();
});

final orderByIdProvider = FutureProvider.family<Order, String>((ref, id) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getOrderById(id);
});

// ─── Addresses ────────────────────────────────────────────────────────────────

final addressesProvider = FutureProvider<List<Address>>((ref) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getAddresses();
});

final selectedAddressProvider = StateProvider<Address?>((ref) => null);

// ─── Create Address ───────────────────────────────────────────────────────────

class CreateAddressNotifier extends StateNotifier<AsyncValue<Address?>> {
  final OrderRepository _repo;

  CreateAddressNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<Address?> create(AddressRequest request) async {
    state = const AsyncValue.loading();
    try {
      final address = await _repo.createAddress(request);
      state = AsyncValue.data(address);
      return address;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final createAddressProvider =
    StateNotifierProvider<CreateAddressNotifier, AsyncValue<Address?>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return CreateAddressNotifier(repo);
});

// ─── Cancel Order ─────────────────────────────────────────────────────────────

class CancelOrderNotifier extends StateNotifier<AsyncValue<void>> {
  final OrderRepository _repo;
  final Ref _ref;

  CancelOrderNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> cancel(String orderId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.cancelOrder(orderId);
      state = const AsyncValue.data(null);
      // Refresh the orders list so the status updates immediately
      _ref.invalidate(ordersProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final cancelOrderProvider =
    StateNotifierProvider<CancelOrderNotifier, AsyncValue<void>>((ref) {
  return CancelOrderNotifier(ref.watch(orderRepositoryProvider), ref);
});

// ─── Shipping Rate ────────────────────────────────────────────────────────────

final shippingRateProvider = StateProvider<double>((ref) => 49.0);

// ─── Checkout State ───────────────────────────────────────────────────────────

enum CheckoutStep { address, review, payment }

final checkoutStepProvider = StateProvider<CheckoutStep>((ref) => CheckoutStep.address);

// ─── Auth State ───────────────────────────────────────────────────────────────

class AuthState {
  final bool isLoggedIn;
  final bool isInitialized; // false until SharedPreferences load completes
  final String? phone;
  final String? name;
  final String? email;
  final String? token;
  final String? photoUrl;

  const AuthState({
    this.isLoggedIn = false,
    this.isInitialized = false,
    this.phone,
    this.name,
    this.email,
    this.token,
    this.photoUrl,
  });
}

// ⚠️ Replace with your Web OAuth Client ID from Google Cloud Console
// → https://console.cloud.google.com → APIs & Services → Credentials
// → Look for "Web client (auto created by Google Service)" → copy Client ID
const _webClientId =
    '241644132012-1g7351j2o2rhg4vd54o7gcpgb900segc.apps.googleusercontent.com';

//241644132012-umohaaq7vpiilg8hgtum2692jfujcdd8.apps.googleusercontent.com
//241644132012-1g7351j2o2rhg4vd54o7gcpgb900segc.apps.googleusercontent.com

final _googleSignIn = GoogleSignIn(serverClientId: _webClientId);
final _authRepository = AuthRepository();

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _loadSaved();
  }

  // ── Restore session from device storage ────────────────────────────────────
  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    if (token != null) {
      state = AuthState(
        isInitialized: true,
        isLoggedIn: true,
        token: token,
        name: prefs.getString(_kName),
        email: prefs.getString(_kEmail),
        phone: prefs.getString(_kPhone),
        photoUrl: prefs.getString(_kPhotoUrl),
      );
    } else {
      state = const AuthState(isInitialized: true);
    }
  }

  // ── Persist session to device storage ─────────────────────────────────────
  Future<void> _saveAuth(AuthState s) async {
    final prefs = await SharedPreferences.getInstance();
    if (s.token != null) await prefs.setString(_kToken, s.token!);
    if (s.name != null) await prefs.setString(_kName, s.name!);
    if (s.email != null) await prefs.setString(_kEmail, s.email!);
    if (s.phone != null) await prefs.setString(_kPhone, s.phone!);
    if (s.photoUrl != null) await prefs.setString(_kPhotoUrl, s.photoUrl!);
  }

  Future<void> _clearSaved() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_kToken),
      prefs.remove(_kName),
      prefs.remove(_kEmail),
      prefs.remove(_kPhone),
      prefs.remove(_kPhotoUrl),
    ]);
  }

  Future<void> signInWithGoogle() async {
    // ── Stage 1: Google Sign-In ───────────────────────────────────────────────
    debugPrint('[AUTH] Stage 1: calling GoogleSignIn.signIn()');
    late final GoogleSignInAccount? googleUser;
    try {
      googleUser = await _googleSignIn.signIn();
    } catch (e) {
      debugPrint('[AUTH] Stage 1 FAILED: $e');
      rethrow;
    }
    if (googleUser == null) throw Exception('Sign-in cancelled by user');
    debugPrint('[AUTH] Stage 1 OK — email: ${googleUser.email}');

    // ── Stage 2: Get tokens ───────────────────────────────────────────────────
    debugPrint('[AUTH] Stage 2: fetching authentication tokens');
    late final GoogleSignInAuthentication googleAuth;
    try {
      googleAuth = await googleUser.authentication;
    } catch (e) {
      debugPrint('[AUTH] Stage 2 FAILED: $e');
      rethrow;
    }
    final idToken = googleAuth.idToken;
    debugPrint('[AUTH] Stage 2 — idToken: ${idToken == null ? 'NULL ❌' : 'present ✓'}');
    if (idToken != null) {
      final parts = idToken.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final padded = payload.padRight(
          payload.length + (4 - payload.length % 4) % 4, '=',
        );
        final decoded = String.fromCharCodes(base64Decode(padded));
        debugPrint('[AUTH] idToken payload: $decoded');
      }
    }
    if (idToken == null) throw Exception('[Stage 2] idToken is null — check serverClientId');

    // ── Stage 3: Backend API call ─────────────────────────────────────────────
    debugPrint('[AUTH] Stage 3: calling backend /api/mobileapi/auth');
    late final AuthResult result;
    try {
      result = await _authRepository.signInWithGoogle(idToken: idToken);
    } catch (e) {
      debugPrint('[AUTH] Stage 3 FAILED: $e');
      rethrow;
    }
    debugPrint('[AUTH] Stage 3 OK — name: ${result.name}, token: ${result.token != null ? 'present ✓' : 'null'}');

    final newState = AuthState(
      isInitialized: true,
      isLoggedIn: true,
      name: result.name ?? googleUser.displayName ?? 'User',
      email: result.email ?? googleUser.email,
      phone: result.phone,
      token: result.token,
      photoUrl: googleUser.photoUrl,
    );
    state = newState;
    await _saveAuth(newState);
    debugPrint('[AUTH] Login complete ✓');
  }

  Future<void> signOut() async {
    state = const AuthState(isInitialized: true); // clear immediately
    await _clearSaved();
    try { await _googleSignIn.signOut(); } catch (_) {}
  }

  Future<void> logout() => signOut();
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
