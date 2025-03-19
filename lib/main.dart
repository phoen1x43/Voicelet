import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voicelet',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FirebaseAuth.instance.currentUser == null ? LoginPage() : MenuPage(),
      routes: {
        '/menu': (context) => MenuPage(),
        '/set': (context) {
          final setNumber = ModalRoute.of(context)!.settings.arguments as int;
          return SetPage(setNumber: setNumber);
        },
        '/addCard': (context) => AddCardPage(),
        '/review': (context) {
          final setNumber = ModalRoute.of(context)!.settings.arguments as int;
          return ReviewPage(setNumber: setNumber);
        },
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _errorMessage = "";

  Future<void> _signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/menu');
    } catch (e) {
      setState(() {
        _errorMessage = "Ошибка входа: ${e.toString()}";
      });
    }
  }

  Future<void> _register() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/menu');
    } catch (e) {
      setState(() {
        _errorMessage = "Ошибка регистрации: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Center(
              child: Image.asset('assets/images/image1.png', width: 150, height: 150),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Voicelet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildTextField(_emailController, "Email", keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 20),
                  _buildTextField(_passwordController, "Пароль", obscureText: true),
                ],
              ),
            ),

            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildButton('Войти', Colors.blue, onTap: _signIn),
                  const SizedBox(height: 20),
                  _buildButton('Регистрация', Colors.grey[300]!, onTap: _register),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildTextField(TextEditingController controller, String hintText, {bool obscureText = false, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      width: 300,
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textAlign: TextAlign.left,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 55,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          border: color == Colors.white ? Border.all(color: Colors.black) : null,
        ),
        child: Center(
          child: Text(text, style: const TextStyle(color: Colors.black, fontSize: 18)),
        ),
      ),
    );
  }
}



class MenuPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 70),
            const Text(
              'Меню',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 90),
            _buildButton('Набор 1', Colors.grey[300]!, onTap: () {
              Navigator.pushNamed(context, '/set', arguments: 1);
            }),
            const SizedBox(height: 25),
            _buildButton('Набор 2', Colors.grey[300]!, onTap: () {
              Navigator.pushNamed(context, '/set', arguments: 2);
            }),
            const SizedBox(height: 25),
            _buildButton('Набор 3', Colors.grey[300]!, onTap: () {
              Navigator.pushNamed(context, '/set', arguments: 3);
            }),
            const SizedBox(height: 150),
            _buildButton('Создать набор', Colors.blue, onTap: () {
              Navigator.pushNamed(context, '/addCard');
            }),
            const Spacer(),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/');
              },
              child: const Text(
                'Сменить аккаунт',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 55,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          border: color == Colors.white ? Border.all(color: Colors.black) : null,
        ),
        child: Center(
          child: Text(text, style: const TextStyle(color: Colors.black, fontSize: 18)),
        ),
      ),
    );
  }
}

class SetPage extends StatelessWidget {
  final int setNumber;

  const SetPage({required this.setNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 70),
            Text(
              'Набор $setNumber',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 20),
              child: const Text(
                'Список карточек:',
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 5, right: 10),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 0),
                    child: ListTile(
                      title: Text(
                        'Карточка ${index + 1}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 0),
            _buildButton('Добавить карточку', Colors.blue, onTap: () {
              Navigator.pushNamed(context, '/addCard');
            }),
            const SizedBox(height: 20),
            _buildButton('Режим проверки', Colors.blue, onTap: () {
              Navigator.pushNamed(context, '/review', arguments: setNumber);
            }),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Назад',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, {double? width, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 300,
        height: 55,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          border: color == Colors.white ? Border.all(color: Colors.black) : null,
        ),
        child: Center(
          child: Text(text, style: const TextStyle(color: Colors.black, fontSize: 18)),
        ),
      ),
    );
  }
}

class AddCardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 70),
          const Text(
            'Карточка',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 60),

          _buildCard('Вопрос (распознанный текст)', height: 170),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/image3.png',
                width: 50,
                height: 50,
              ),
              const SizedBox(width: 40),
              _buildSmallButton('Запись', Colors.grey[300]!),
            ],
          ),
          const SizedBox(height: 40),

          _buildCard('Ответ (распознанный текст)', height: 170),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/image3.png',
                width: 50,
                height: 50,
              ),
              const SizedBox(width: 40),
              _buildSmallButton('Запись', Colors.grey[300]!),
            ],
          ),
          const SizedBox(height: 110),

          _buildButton('Добавить карточку', Colors.blue),
          const SizedBox(height: 70),

          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Назад',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCard(String text, {double height = 100}) {
    return Container(
      width: 300,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSmallButton(String text, Color color) {
    return Container(
      width: 200,
      height: 35,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color) {
    return Container(
      width: 300,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class ReviewPage extends StatelessWidget {
  final int setNumber;

  const ReviewPage({required this.setNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 70),
          Text(
            'Набор $setNumber',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 60),

          _buildCard('Вопрос на карточке', height: 170),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/image3.png',
                width: 50,
                height: 50,
              ),
              const SizedBox(width: 40),
              _buildSmallButton('Запись', Colors.grey[300]!),
            ],
          ),
          const SizedBox(height: 40),

          _buildCard('Распознанный ответ', height: 170),
          const SizedBox(height: 80),

          _buildButton('Далее', Colors.lightBlue),
          const SizedBox(height: 150),

          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Завершить',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCard(String text, {double height = 100}) {
    return Container(
      width: 300,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSmallButton(String text, Color color) {
    return Container(
      width: 200,
      height: 35,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color) {
    return Container(
      width: 300,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}


