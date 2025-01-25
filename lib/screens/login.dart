import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:home_ease/screens/admin.dart';
import 'package:home_ease/screens/forgot_password.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool isAdminLogin = false;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<Offset> _slideAnimation2;

  final TextEditingController _userEmailController = TextEditingController();
  final TextEditingController _userPasswordController = TextEditingController();
  final TextEditingController _adminUsernameController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-1, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation2 = Tween<Offset>(
      begin: const Offset(1, 0),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _userEmailController.dispose();
    _userPasswordController.dispose();
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleAdminLogin() {
    setState(() {
      if (isAdminLogin) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
      isAdminLogin = !isAdminLogin;

      _userEmailController.clear();
      _userPasswordController.clear();
      _adminUsernameController.clear();
      _adminPasswordController.clear();
    });
  }

  Future<void> _loginUser() async {
    if (_userEmailController.text.isEmpty || _userPasswordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _userEmailController.text.trim(),
        password: _userPasswordController.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(userId: userCredential.user!.uid),
        ),
      );
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'Login failed');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> updateLastActive() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'lastActiveDate': FieldValue.serverTimestamp(),
    });
  }
}

 Future<void> _loginAdmin() async {
  if (_adminUsernameController.text.isEmpty || _adminPasswordController.text.isEmpty) {
    _showSnackBar('Please fill in all fields');
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Add security rules in Firebase Console for admins collection:
    // match /admins/{adminId} {
    //   allow read: if request.auth != null;
    // }
    
    final QuerySnapshot adminSnapshot = await _firestore
        .collection('admins')
        .where('username', isEqualTo: _adminUsernameController.text.trim())
        .get();

    if (adminSnapshot.docs.isEmpty) {
      _showSnackBar('Admin not found');
      return;
    }

    final adminDoc = adminSnapshot.docs.first;
    if (adminDoc.data() is Map && adminDoc['password'] == _adminPasswordController.text.trim()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboard()),
      );
    } else {
      _showSnackBar('Invalid credentials');
    }
  } catch (e) {
    _showSnackBar('Error: ${e.toString()}');
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color.fromRGBO(183, 147, 254, 1),
                  Color.fromRGBO(136, 191, 255, 1),
                ],
              ),
            ),
          ),
          SlideTransition(
            position: _slideAnimation,
            child: _buildUserLoginForm(),
          ),
          SlideTransition(
            position: _slideAnimation2,
            child: _buildAdminLoginForm(),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  isAdminLogin ? Icons.person : Icons.admin_panel_settings,
                  key: ValueKey<bool>(isAdminLogin),
                  color: Colors.white,
                  size: 28,
                ),
              ),
              onPressed: _toggleAdminLogin,
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignupScreen()),
                  );
                },
                child: const Text(
                  'Create an Account',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserLoginForm() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            _inputField(_userEmailController, 'Email', Icons.email),
            const SizedBox(height: 16),
            _inputField(_userPasswordController, 'Password', Icons.lock, isPassword: true),
            const SizedBox(height: 24),
            _loginButton(_loginUser),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                );
              },
              child: const Text('Forgot Password?', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminLoginForm() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            _inputField(_adminUsernameController, 'Username', Icons.person),
            const SizedBox(height: 16),
            _inputField(_adminPasswordController, 'Password', Icons.lock, isPassword: true),
            const SizedBox(height: 24),
            _loginButton(_loginAdmin),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String hintText, IconData icon,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(hintText: hintText, prefixIcon: Icon(icon)),
    );
  }

  Widget _loginButton(VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      child: _isLoading 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Continue'),
    );
  }
}