import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';


class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static AuthService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;


  User? get currentUser => _supabase.auth.currentUser;


  String? get accessToken => _supabase.auth.currentSession?.accessToken;


  bool get isLoggedIn => currentUser != null;


  String? get userEmail => currentUser?.email;
  String? get sub => currentUser?.userMetadata?['sub'] as String?;


  String? get userUsername => currentUser?.userMetadata?['username'] as String?;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;




  Future<void> initialize(String supabaseUrl, String supabaseAnonKey) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    _supabase.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }



  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String username,
    required String password,
}) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      notifyListeners();
      return response;
    }
    catch (e) {
      rethrow;
    }
  }


  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse?> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      notifyListeners();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserResponse> updateUser({
    String? email,
    String? password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(
          email: email,
          password: password,
          data: data,
        ),
      );
      notifyListeners();
      return response;
    } catch (e) {
      rethrow;
    }
  }
}