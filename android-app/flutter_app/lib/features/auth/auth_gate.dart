import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
          return const Center(child: Text('Please sign in'));
        }
        return FutureBuilder<IdTokenResult>(
          future: user.getIdTokenResult(true),
          builder: (context, tokenSnap) {
            if (!tokenSnap.hasData) return const Center(child: CircularProgressIndicator());
            final role = tokenSnap.data!.claims?['role']?.toString() ?? 'teacher';
            return Center(child: Text('Signed in as $role'));
          },
        );
      },
    );
  }
}
