import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _user = _auth.currentUser;
      if (_user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "No user is currently signed in.";
        });
        return;
      }

      DocumentSnapshot userDoc =
          await _firestore.collection("users").doc(_user!.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
        });
      } else {
        setState(() {
          _errorMessage = "User data not found in Firestore.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching data: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _logout() {
    _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.indigo.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : _userData == null
                  ? const Center(child: Text("No user data available."))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundImage: AssetImage('assets/profile_placeholder.png'),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _userData!["fullName"] ?? "N/A",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _userData!["email"] ?? "N/A",
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Phone: ${_userData!["phone"] ?? "N/A"}",
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.edit, color: Colors.blue),
                            title: const Text("Edit Profile"),
                            onTap: () {
                              // Implement profile editing functionality
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.lock, color: Colors.orange),
                            title: const Text("Change Password"),
                            onTap: () {
                              // Implement password change functionality
                            },
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout),
                            label: const Text("Logout"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
    );
  }
}
