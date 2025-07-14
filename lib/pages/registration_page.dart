import 'dart:io';

import 'package:easy_vahan/consts.dart';
import 'package:easy_vahan/services/auth_services.dart';
import 'package:easy_vahan/services/media_service.dart';
import 'package:easy_vahan/services/navigation_service.dart';
import 'package:easy_vahan/widgest/custom_form_field.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GetIt _getIt = GetIt.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late MediaService _mediaService;
  late NavigationService _navigationService;
  late AuthService _authService;
  File? selectedImage;
  String? email, password, name;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _mediaService = _getIt.get<MediaService>();
    _navigationService = _getIt.get<NavigationService>();
    _authService = _getIt.get<AuthService>();
  }
  
  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      
      if (email == null || password == null || name == null) {
        _showError('Please fill in all required fields');
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        bool success = await _authService.register(
          email!,
          password!,
          displayName: name,
        );
        
        if (success && mounted) {
          _showSuccess('Registration successful! Please login');
          // Wait a moment to show success message, then go back to login
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            _navigationService.goBack(); // This will take us back to the login page
          }
        }
      } catch (e) {
        if (mounted) {
          _showError(e.toString());
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 15.0,
          vertical: 20.0,
        ),
        child: Column(
          children: [
            _headerText(),
            _registerForm(),
            _registerButton(),
            _loginAccountLink(),
          ],
        ),
      ),
    );
  }

  Widget _headerText() {
    return SizedBox(
        width: MediaQuery.sizeOf(context).width,
        child: const Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Let's get going!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              "Register an account using form below",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            )
          ],
        ));
  }

  Widget _registerForm() {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.60,
      margin: EdgeInsets.symmetric(
        vertical: MediaQuery.sizeOf(context).height * 0.05,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _pfpSelectionFeild(),
              const SizedBox(height: 16),
              CustomFormField(
                height: MediaQuery.sizeOf(context).height * 0.10,
                hintText: "Name",
                validationRegEx: NAME_VALIDATION_REGEX,
                obsecureText: false,
                onSaved: (value) {
                  name = value;
                },
              ),
              const SizedBox(height: 8),
              CustomFormField(
                height: MediaQuery.sizeOf(context).height * 0.10,
                hintText: "Email",
                validationRegEx: EMAIL_VALIDATION_REGEX,
                obsecureText: false,
                keyboardType: TextInputType.emailAddress,
                onSaved: (value) {
                  email = value?.trim();
                },
              ),
              const SizedBox(height: 8),
              CustomFormField(
                height: MediaQuery.sizeOf(context).height * 0.10,
                hintText: "Password",
                validationRegEx: PASSWORD_VALIDATION_REGEX,
                obsecureText: true,
                onSaved: (value) {
                  password = value;
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pfpSelectionFeild() {
    return GestureDetector(
      onTap: () async {
        File? file = await _mediaService.getImageFromGallery();
        if (file != null) {
          setState(() {
            selectedImage = file;
          });
        }
      },
      child: CircleAvatar(
        radius: MediaQuery.of(context).size.width * 0.15,
        backgroundImage: selectedImage != null
            ? FileImage(selectedImage!)
            : const NetworkImage(PLACEHOLDER_PFP) as ImageProvider,
      ),
    );
  }

  Widget _registerButton() {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: MaterialButton(
        onPressed: _isLoading ? null : _register,
        color: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "Register",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _loginAccountLink() {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text("Already have and account?"),
          GestureDetector(
            onTap: () {
              _navigationService.goBack();
            },
            child: const Text(
              "Login",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          )
        ],
      ),
    );
  }
}
