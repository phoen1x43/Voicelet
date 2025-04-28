import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
          final setId = ModalRoute.of(context)!.settings.arguments as String;
          return SetPage(setId: setId);
        },
        '/addCard': (context) {
          final setId = ModalRoute.of(context)!.settings.arguments as String;
          return AddCardPage(setId: setId);
        },
        '/review': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return ReviewPage(
            setId: args['setId'],
            setTitle: args['setTitle'],
          );
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

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _sets = [];

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final setsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sets')
        .orderBy('createdAt')
        .get();

    setState(() {
      _sets = setsSnapshot.docs
          .map((doc) => {
        'id': doc.id,
        'title': doc.data()['title'] ?? 'Без названия',
      })
          .toList();
    });
  }

  Future<void> _showCreateSetDialog() async {
    String newTitle = '';
    final user = _auth.currentUser;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Создать новый набор'),
          content: SizedBox(
            width: 300,
            child: TextField(
              decoration: const InputDecoration(hintText: 'Название набора'),
              onChanged: (value) => newTitle = value,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newTitle.trim().isEmpty || user == null) return;
                await _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('sets')
                    .add({
                      'title': newTitle.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                await _loadSets();
              },
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 90),
            const Text(
              'Меню',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: _sets.isEmpty
                  ? const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Text(
                  "У вас пока нет наборов",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
                  : ListView.builder(
                itemCount: _sets.length,
                itemBuilder: (context, index) {
                  final set = _sets[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: _buildButton(
                        set['title'],
                        Colors.grey[300]!,
                        onTap: () async {
                          await Navigator.pushNamed(context, '/set', arguments: set['id']);
                          await _loadSets();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildButton('Создать набор', Colors.blue, onTap: () async {
              await _showCreateSetDialog();
            }),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                      (Route<dynamic> route) => false,
                );
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
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: Colors.black, fontSize: 18),
          ),
        ),
      ),
    );
  }
}




class SetPage extends StatefulWidget {
  final String setId;

  const SetPage({required this.setId});

  @override
  _SetPageState createState() => _SetPageState();
}

class _SetPageState extends State<SetPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _cards = [];
  String _setTitle = "";

  @override
  void initState() {
    super.initState();
    _loadSetData();
  }

  Future<void> _loadSetData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final setDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sets')
        .doc(widget.setId)
        .get();

    final cardsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sets')
        .doc(widget.setId)
        .collection('cards')
        .get();

    setState(() {
      _setTitle = setDoc.data()?['title'] ?? 'Набор';
      _cards = cardsSnapshot.docs.asMap().entries.map((entry) {
        int index = entry.key + 1;
        var doc = entry.value;
        return {
          'id': doc.id,
          'title': 'Карточка $index',
          'question': doc.data()['question']?.replaceAll(RegExp(r'^Карточка \d+:\s*'), '') ?? '',
          'answer': doc.data()['answer'] ?? '',
        };
      }).toList();
    });
  }

  void _openEditDialog(Map<String, dynamic> card) {
    final questionController = TextEditingController(text: card['question']);
    final answerController = TextEditingController(text: card['answer']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать карточку'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: questionController,
              decoration: const InputDecoration(labelText: 'Вопрос'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: answerController,
              decoration: const InputDecoration(labelText: 'Ответ'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // 👈 Кнопка Назад
            child: const Text('Назад'),
          ),
          TextButton(
            onPressed: () async {
              final user = _auth.currentUser;
              if (user == null) return;
              await _firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('sets')
                  .doc(widget.setId)
                  .collection('cards')
                  .doc(card['id'])
                  .delete();
              Navigator.pop(context);
              _loadSetData();
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = _auth.currentUser;
              if (user == null) return;
              await _firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('sets')
                  .doc(widget.setId)
                  .collection('cards')
                  .doc(card['id'])
                  .update({
                'question': questionController.text,
                'answer': answerController.text,
              });
              Navigator.pop(context);
              _loadSetData();
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Text(
              _setTitle,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  'Список карточек:',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _cards.isEmpty
                  ? const Center(
                child: Text(
                  'Пока нет карточек',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
              )
                  : ListView.builder(
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  return ListTile(
                    title: Text(
                      card['title'],
                      style: const TextStyle(fontSize: 20),
                    ),
                    onTap: () => _openEditDialog(card),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildButton('Добавить карточку', Colors.blue, onTap: () async {
              await Navigator.pushNamed(context, '/addCard', arguments: widget.setId);
              _loadSetData();
            }),
            const SizedBox(height: 20),
            _buildButton('Режим проверки', Colors.blue, onTap: () {
              Navigator.pushNamed(
                context,
                '/review',
                arguments: {
                  'setId': widget.setId,
                  'setTitle': _setTitle,
                },
              );
            }),
            const SizedBox(height: 20),
            _buildButton('Удалить набор', Colors.red, onTap: () async {
              final user = _auth.currentUser;
              if (user == null) return;
              await _firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('sets')
                  .doc(widget.setId)
                  .delete();
              Navigator.pop(context);
            }),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Назад',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
            const SizedBox(height: 30),
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
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: Colors.black, fontSize: 18),
          ),
        ),
      ),
    );
  }
}


class AddCardPage extends StatefulWidget {
  final String setId;

  const AddCardPage({required this.setId});

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _addCard() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cardsRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sets')
        .doc(widget.setId)
        .collection('cards');

    final snapshot = await cardsRef.get();
    final index = snapshot.docs.length + 1;

    await cardsRef.add({
      'question': 'Карточка $index: ${_questionController.text.trim()}',
      'answer': _answerController.text.trim(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                'Карточка',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 60),

              _buildCardField(_questionController, 'Вопрос (распознанный текст)', height: 170),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/image3.png', width: 50, height: 50),
                  const SizedBox(width: 40),
                  _buildSmallButton('Запись', Colors.grey[300]!),
                ],
              ),
              const SizedBox(height: 40),

              _buildCardField(_answerController, 'Ответ (распознанный текст)', height: 170),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/image3.png', width: 50, height: 50),
                  const SizedBox(width: 40),
                  _buildSmallButton('Запись', Colors.grey[300]!),
                ],
              ),
              const SizedBox(height: 60),

              GestureDetector(
                onTap: _addCard,
                child: Container(
                  width: 300,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Text(
                      'Добавить карточку',
                      style: TextStyle(color: Colors.black, fontSize: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),

              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Назад',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardField(TextEditingController controller, String hint, {double height = 100}) {
    return Container(
      width: 300,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          contentPadding: const EdgeInsets.all(10),
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
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
      ),
    );
  }
}



class ReviewPage extends StatefulWidget {
  final String setId;
  final String setTitle;

  const ReviewPage({required this.setId, required this.setTitle});

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _cards = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cardsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sets')
        .doc(widget.setId)
        .collection('cards')
        .get();

    setState(() {
      _cards = cardsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'question': data['question']?.replaceAll(RegExp(r'^Карточка \d+:\s*'), '') ?? '',
          'answer': data['answer'] ?? '',
        };
      }).toList();
    });
  }

  void _nextCard() {
    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCard = _cards.isNotEmpty ? _cards[_currentIndex] : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Text(
              widget.setTitle,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            _buildCard(currentCard != null ? currentCard['question'] : 'Вопрос на карточке', height: 225),
            const SizedBox(height: 50),
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
            const SizedBox(height: 50),
            _buildCard('Распознанный ответ', height: 170),
            const SizedBox(height: 60),
            _buildButton('Далее', Colors.lightBlue, onTap: _nextCard),
            const SizedBox(height: 80),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Завершить',
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String text, {double height = 100}) {
    return Container(
      width: 320,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            text,
            style: const TextStyle(color: Colors.black, fontSize: 16),
            textAlign: TextAlign.center,
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
        borderRadius: BorderRadius.circular(15),
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

  Widget _buildButton(String text, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}





