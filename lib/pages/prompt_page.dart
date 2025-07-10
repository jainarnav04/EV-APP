import 'package:flutter/material.dart';

class PromptPage extends StatefulWidget {
  const PromptPage({super.key});

  @override
  _PromptPageState createState() => _PromptPageState();
}

class _PromptPageState extends State<PromptPage> {
  final TextEditingController _batteryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _showBatteryPrompt(context));
  }

  void _showBatteryPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter SOC/Battery State'),
          content: TextField(
            controller: _batteryController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: "Enter battery percentage"),
          ),
          actions: <Widget>[
            MaterialButton(
              child: const Text('Submit'),
              onPressed: () {
                // TODO: Handle the submission logic
                print('Battery State: ${_batteryController.text}');
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: const Center(
        child: Text('Welcome to the Home Page!'),
      ),
    );
  }
}
