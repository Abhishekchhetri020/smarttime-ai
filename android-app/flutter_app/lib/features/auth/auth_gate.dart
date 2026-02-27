import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../timetable/role_screens.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snap.data;
        if (user == null) {
          return const SignInPanel();
        }
        return FutureBuilder<IdTokenResult>(
          future: user.getIdTokenResult(true),
          builder: (context, tokenSnap) {
            if (!tokenSnap.hasData) return const Center(child: CircularProgressIndicator());
            final role = tokenSnap.data!.claims?['role']?.toString() ?? 'teacher';
            Widget child;
            switch (role) {
              case 'super_admin':
                child = const SuperAdminScreen();
                break;
              case 'incharge':
                child = const InchargeScreen();
                break;
              case 'student':
                child = const StudentScreen();
                break;
              case 'parent':
                child = const ParentScreen();
                break;
              case 'teacher':
              default:
                child = const TeacherScreen();
            }
            return Column(
              children: [
                Expanded(child: child),
                TextButton(
                  onPressed: () async => FirebaseAuth.instance.signOut(),
                  child: const Text('Sign Out'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class SignInPanel extends StatefulWidget {
  const SignInPanel({super.key});

  @override
  State<SignInPanel> createState() => _SignInPanelState();
}

class _SignInPanelState extends State<SignInPanel> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _err = '';
  bool _loading = false;

  Future<void> _signIn({required bool create}) async {
    setState(() {
      _err = '';
      _loading = true;
    });
    try {
      final auth = FirebaseAuth.instance;
      if (create) {
        await auth.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await auth.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _err = '';
      _loading = true;
    });
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sign in to SmartTime AI'),
            const SizedBox(height: 12),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 12),
            if (_err.isNotEmpty) Text(_err, style: const TextStyle(color: Colors.red)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _loading ? null : () => _signIn(create: false),
                  child: const Text('Sign In'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _loading ? null : () => _signIn(create: true),
                  child: const Text('Create Account'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loading ? null : _googleSignIn,
              child: const Text('Continue with Google'),
            ),
          ],
        ),
      ),
    );
  }
}
