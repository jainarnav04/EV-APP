import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  AuthService() {
    // Listen to auth state changes
    _firebaseAuth.authStateChanges().listen((User? user) {
      _user = user;
    });
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      
      if (email.isEmpty || password.isEmpty) {
        throw 'Please enter both email and password';
      }
      
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      _user = credential.user;
      return _user != null;
      
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid';
      } else if (e.code == 'user-disabled') {
        message = 'This user account has been disabled';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many login attempts. Please try again later';
      }
      
      throw message;
      
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<bool> logout() async {
    try {
      await _firebaseAuth.signOut();
      _user = null;
      return true;
    } catch (e) {
      print('Logout error: $e');
      rethrow;
    }
  }
  
  // Register a new user with email and password
  Future<bool> register(String email, String password, {String? displayName}) async {
    try {
      _isLoading = true;
      
      if (email.isEmpty || password.isEmpty) {
        throw 'Please enter both email and password';
      }
      
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Update user display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
        await credential.user?.reload();
        _user = _firebaseAuth.currentUser;
      }
      
      return credential.user != null;
      
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred during registration';
      
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Email/password accounts are not enabled';
      }
      
      throw message;
      
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
    }
  }
  
  // Check if user is logged in
  bool get isLoggedIn => _user != null;
}
