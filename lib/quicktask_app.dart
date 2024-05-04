import 'package:flutter/material.dart';
import 'home.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class QuickTask extends StatefulWidget {
  const QuickTask({super.key, required this.token, required this.username});
  final String token;
  final String username;
  @override
  _QuickTaskState createState() => _QuickTaskState();
}

class _QuickTaskState extends State<QuickTask> {
  final taskController = TextEditingController();
  void addTask() async {
    if (taskController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Empty title"),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    await saveTask(taskController.text, widget.username, widget.token);
    setState(() {
      taskController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("QuickTask App"),
        backgroundColor: Colors.blueAccent,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
              padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      autocorrect: true,
                      textCapitalization: TextCapitalization.sentences,
                      controller: taskController,
                      decoration: InputDecoration(
                          labelText: "New Task",
                          labelStyle: TextStyle(color: Colors.blueAccent)),
                    ),
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueAccent,
                      ),
                      onPressed: addTask,
                      child: Text("ADD")),
                ],
              )),
          Expanded(
              child: FutureBuilder<List<dynamic>>(
                  future: getTask(widget.token),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.none:
                      case ConnectionState.waiting:
                        return Center(
                          child: Container(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator()),
                        );
                      default:
                        if (snapshot.hasError) {
                          return Center(
                            child: Text("Error..."),
                          );
                        }
                        if (!snapshot.hasData) {
                          return Center(
                            child: Text("No Data..."),
                          );
                        } else {
                          return ListView.builder(
                              padding: EdgeInsets.only(top: 10.0),
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                final vartask = snapshot.data![index];
                                final varTitle = vartask['title']!;
                                final varDone =  vartask['done']!;
                                return ListTile(
                                  title: Text(varTitle),
                                  leading: CircleAvatar(
                                    child: Icon(
                                        varDone ? Icons.check : Icons.error),
                                    backgroundColor:
                                        varDone ? Colors.green : Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                          value: varDone,
                                          onChanged: (value) async {
                                            await updateTask(
                                                vartask['objectId']!, value!, widget.token);
                                            setState(() {
                                            });
                                          }),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () async {
                                          await deleteTask(vartask['objectId']!, widget.token);
                                          setState(() {
                                            const snackBar = SnackBar(
                                              content: Text("Task deleted!"),
                                              duration: Duration(seconds: 2),
                                            );
                                            ScaffoldMessenger.of(context)
                                              ..removeCurrentSnackBar()
                                              ..showSnackBar(snackBar);
                                          });
                                        },
                                      )
                                    ],
                                  ),
                                );
                              });
                        }
                    }
                  }))
        ],
      ),
    );
  }

  Future<void> saveTask(String title, String username, String token) async {
    var url = '${dotenv.env['BACKEND_API_URL']!}/task/add';
    final Map<String, dynamic> postData = {
      'username': username,
      'title': title,
      'done': false,
    };

    try {
      final response = await http.post(
          Uri.parse(url),
          body: jsonEncode(postData),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
        );

      if (response.statusCode == 201) {
        print('Response: ${response.body}');
      } else {
        print('Error: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Exception: $error');
    }
  }

  Future<List<dynamic>> getTask(String token) async {
    var url = '${dotenv.env['BACKEND_API_URL']!}/task/getall';

    try {
      final response = await http.get(
          Uri.parse(url),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
        );
        
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      } else {
        print('Error: ${response.reasonPhrase}');
        return [];
      }
    } catch (error) {
      print('Exception: $error');
      return [];
    }
  }

  Future<void> updateTask(String id, bool done, String token) async {
    var url = '${dotenv.env['BACKEND_API_URL']!}/task/update';
    final Map<String, dynamic> postData = {
      'objectId': id,
      'done': done,
    };

    try {
      final response = await http.patch(
          Uri.parse(url),
          body: jsonEncode(postData),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
        );
        
      if (response.statusCode == 200) {
        print('Response: ${response.body}');
      } else {
        print('Error: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Exception: $error');
    }
  }

  Future<void> deleteTask(String id, String token) async {
    var url = '${dotenv.env['BACKEND_API_URL']!}/task/delete';
    final Map<String, dynamic> postData = {
      'objectId': id
    };

    try {
      final response = await http.delete(
          Uri.parse(url),
          body: jsonEncode(postData),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
        );
        
      if (response.statusCode == 200) {
        print('Response: ${response.body}');
      } else {
        print('Error: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Exception: $error');
    }
  }
}