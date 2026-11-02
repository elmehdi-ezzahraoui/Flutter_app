import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  const AuthService();

  GoTrueClient get _auth => Supabase.instance.client.auth;

  Future<User?> signUpWithEmailAndPassword(
    String email,
    String password, {
    String role = 'citizen',
  }) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: {'role': role},
    );
    return response.user;
  }

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final response = await _auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user;
  }

  Future<void> signOut() => _auth.signOut();

  Stream<User?> get authStateChanges =>
      _auth.onAuthStateChange.map((state) => state.session?.user);

  User? get currentUser => _auth.currentUser;

  /// Récupère le rôle de l'utilisateur : 'citizen' ou 'worker'
  Future<String> getUserRole([String? userId]) async {
    final uid = userId ?? _auth.currentUser?.id;
    if (uid == null) return 'citizen';

    try {
      // 1. Vérifie dans user_metadata
      final metaRole = _auth.currentUser?.userMetadata?['role']?.toString();
      if (metaRole != null && (metaRole == 'citizen' || metaRole == 'worker')) {
        return metaRole;
      }

      // 2. Requête dans la table public.profiles
      final res = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .maybeSingle();

      if (res != null && res['role'] != null) {
        final r = res['role'].toString();
        if (r == 'citizen' || r == 'worker') return r;
      }
    } catch (_) {}

    return 'citizen';
  }
}
