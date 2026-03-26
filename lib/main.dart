import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const WaterReminderApp());
}

class WaterReminderApp extends StatelessWidget {
  const WaterReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paani Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E90FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _glassCount = 0;
  int _dailyGoal = 8;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _loadData();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('last_date') ?? '';
    final today = DateTime.now().toString().substring(0, 10);

    if (savedDate != today) {
      await prefs.setInt('glass_count', 0);
      await prefs.setString('last_date', today);
    }

    setState(() {
      _glassCount = prefs.getInt('glass_count') ?? 0;
      _dailyGoal = prefs.getInt('daily_goal') ?? 8;
    });
  }

  Future<void> _addGlass() async {
    if (_glassCount >= _dailyGoal) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() => _glassCount++);
    await prefs.setInt('glass_count', _glassCount);
    _animController.forward().then((_) => _animController.reverse());

    if (_glassCount == _dailyGoal) {
      _showGoalComplete();
    }
  }

  Future<void> _removeGlass() async {
    if (_glassCount <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() => _glassCount--);
    await prefs.setInt('glass_count', _glassCount);
  }

  void _showGoalComplete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Shabash!', textAlign: TextAlign.center),
        content: const Text(
          'Aapne aaj ka paani ka goal poora kar liya!\nBahut achha!',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Shukriya!'),
          ),
        ],
      ),
    );
  }

  void _changeGoal() {
    showDialog(
      context: context,
      builder: (_) {
        int tempGoal = _dailyGoal;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Daily Goal Badlo'),
          content: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$tempGoal glasses',
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold)),
                Slider(
                  value: tempGoal.toDouble(),
                  min: 4,
                  max: 16,
                  divisions: 12,
                  onChanged: (v) =>
                      setDialogState(() => tempGoal = v.toInt()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                setState(() => _dailyGoal = tempGoal);
                await prefs.setInt('daily_goal', tempGoal);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  double get _progress => _dailyGoal == 0 ? 0 : _glassCount / _dailyGoal;

  String get _motivationText {
    if (_glassCount == 0) return 'Chalo shuru karte hain! 💪';
    if (_progress < 0.3) return 'Achhi shuruwat! Paani pite raho 😊';
    if (_progress < 0.6) return 'Bahut achha! Aadha ho gaya! 🌊';
    if (_progress < 1.0) return 'Bas thoda sa baki hai! 🔥';
    return 'Goal complete! Aap amazing hain! 🎉';
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E90FF),
        foregroundColor: Colors.white,
        title: const Text('💧 Paani Tracker',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _changeGoal,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 16,
                      backgroundColor: Colors.blue.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _progress >= 1.0
                            ? Colors.green
                            : const Color(0xFF1E90FF),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: Text(
                          '$_glassCount',
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E90FF),
                          ),
                        ),
                      ),
                      Text(
                        '/ $_dailyGoal glasses',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _motivationText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${(_glassCount * 250)} ml / ${(_dailyGoal * 250)} ml',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _addGlass,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _glassCount >= _dailyGoal
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [
                              const Color(0xFF1E90FF),
                              const Color(0xFF0066CC),
                            ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E90FF).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('💧', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 4),
                      Text(
                        _glassCount >= _dailyGoal ? 'Done! ✅' : 'Peea!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _removeGlass,
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('Galti se daba diya? Hatao'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: List.generate(_dailyGoal, (i) {
                  return Text(
                    i < _glassCount ? '💧' : '🔵',
                    style: const TextStyle(fontSize: 24),
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
