import 'package:flutter/material.dart';
import 'quicktask_app.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loginUser,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  void _loginUser() async {
    try {
      if (_usernameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please enter username"),
          duration: Duration(seconds: 2),
        ));
        return;
      } else if (_passwordController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please enter password"),
          duration: Duration(seconds: 2),
        ));
        return;
      }

      String username = _usernameController.text.trim();
      String password = _passwordController.text.trim();
      Map<String, String> response = await loginUser(username, password);
      if (response['token'] != null && response['token']!.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => QuickTask(token: response['token'] ?? '', username: username,)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response['error'] ?? ''),
          duration: Duration(seconds: 2),
        ));
        return;
      }
    } catch (e) {
      print('Error logging in: $e');
    }
  }

  Future<Map<String, String>> loginUser(String username, String password) async {
    var url = '${dotenv.env['BACKEND_API_URL']!}/login';

    final Map<String, String> postData = {
      'username': username,
      'password': password,
    };

    try {
      final response = await http.post(
          Uri.parse(url),
          body: jsonEncode(postData),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        );
        
      dynamic decodedBody = jsonDecode(response.body);
      Map<String, String> resultMap = {};
      if (decodedBody is Map) {
        decodedBody.forEach((key, value) {
          resultMap[key.toString()] = value.toString();
        });
      }
      return resultMap;
    } catch (error) {
      print('Exception: $error');
      return {'error': 'Login failed'};
    }
  }
}
