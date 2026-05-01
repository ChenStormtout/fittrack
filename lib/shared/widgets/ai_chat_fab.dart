import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/ai_nutrition_service.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/nutrition/controllers/nutrition_controller.dart';

// ── Demo responses when API is not configured ──────────────────
const _demoResponses = [
  'Untuk hasil optimal, pastikan kamu mengonsumsi protein minimal 1.6g per kg berat badan setiap hari! 💪',
  'Minum air putih minimal 8 gelas per hari sangat penting untuk metabolisme dan performa latihan. 💧',
  'Istirahat yang cukup (7-8 jam) sama pentingnya dengan latihan itu sendiri untuk recovery otot. 😴',
  'Sarapan berprotein tinggi seperti telur atau oatmeal bisa membantu kamu kenyang lebih lama dan menjaga energi. 🥚',
  'HIIT 20-30 menit lebih efektif membakar lemak dibanding cardio steady-state 1 jam! 🔥',
  'Konsumsi karbohidrat kompleks seperti nasi merah atau ubi sebelum latihan untuk energi yang tahan lama. 🍠',
  'Stretching selama 10 menit setelah latihan dapat mengurangi DOMS (nyeri otot setelah olahraga). 🧘',
];

int _demoIndex = 0;
String _getDemoResponse() {
  final r = _demoResponses[_demoIndex % _demoResponses.length];
  _demoIndex++;
  return r;
}

// ── FAB Widget ────────────────────────────────────────────────
class AiChatFab extends StatelessWidget {
  const AiChatFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _openChat(context),
      backgroundColor: AppColors.primary,
      elevation: 6,
      tooltip: 'FitAI Coach',
      child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 26),
    );
  }

  void _openChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AiChatSheet(),
    );
  }
}

// ── Chat Bottom Sheet ─────────────────────────────────────────
class _AiChatSheet extends StatefulWidget {
  const _AiChatSheet();

  @override
  State<_AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<_AiChatSheet> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  static const _suggestions = [
    '💪 Tips latihan hari ini',
    '🥗 Rekomendasi makanan sehat',
    '💧 Kebutuhan air harianku',
    '🔥 Cara bakar kalori lebih cepat',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'assistant',
      'text':
          'Halo! Saya FitAI Coach 🤖\nSiap membantu pertanyaan tentang nutrisi, latihan, dan tips fitness kamu. Ada yang bisa saya bantu?',
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _isTyping) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
      if (preset == null) _controller.clear();
    });
    _scrollToBottom();

    try {
      final nutritionCtrl = context.read<NutritionController>();
      final user = context.read<AuthController>().currentUser;
      final ctx = {
        'totalCalories': nutritionCtrl.totalCalories,
        'targetCalories': 2000,
        'totalProtein': nutritionCtrl.totalProtein,
        'totalCarbs': nutritionCtrl.totalCarbs,
        'totalFat': nutritionCtrl.totalFat,
        'totalWater': nutritionCtrl.totalWaterMl,
        'targetWater': 2000,
        'goal': user?.goal ?? 'Maintain',
        'mealLog': <Map<String, dynamic>>[],
      };

      String response;
      try {
        response = await AiNutritionService.instance.askCoach(
          userMessage: text,
          nutritionContext: ctx,
        );
        // If API key not set, fall back to demo
        if (response.contains('kesalahan') || response.contains('tidak tersedia')) {
          response = _getDemoResponse();
        }
      } catch (_) {
        response = _getDemoResponse();
      }

      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'assistant', 'text': response});
        _isTyping = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'assistant', 'text': _getDemoResponse()});
        _isTyping = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      maxChildSize: 0.95,
      minChildSize: 0.45,
      expand: false,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _handle(),
            _header(),
            Expanded(child: _messageList(sc)),
            if (_messages.length <= 1) _quickSuggestions(),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _handle() => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _header() => Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FitAI Coach',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  Text('AI Nutrition & Fitness Assistant',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, color: Color(0xFF90EE90), size: 8),
                  SizedBox(width: 4),
                  Text('Online', style: TextStyle(color: Colors.white, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _messageList(ScrollController sc) => ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        itemCount: _messages.length + (_isTyping ? 1 : 0),
        itemBuilder: (_, i) {
          if (_isTyping && i == _messages.length) return const _TypingBubble();
          final m = _messages[i];
          return _MessageBubble(text: m['text']!, isUser: m['role'] == 'user');
        },
      );

  Widget _quickSuggestions() => SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: _suggestions
              .map((s) => GestureDetector(
                    onTap: () => _send(s.substring(2).trim()),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.softAccent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(s,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ))
              .toList(),
        ),
      );

  Widget _inputBar() => Container(
        padding: EdgeInsets.fromLTRB(
            14, 10, 14, MediaQuery.of(context).viewInsets.bottom + 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Tanya FitAI Coach...',
                  hintStyle:
                      const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.softCard,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _send(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isTyping ? AppColors.sage : AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: _isTyping
                    ? const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      );
}

// ── Message Bubble ────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _MessageBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.softCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 6),
        ],
      ),
    );
  }
}

// ── Typing Indicator ──────────────────────────────────────────
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.softCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final t = ((_ctrl.value - i * 0.25) % 1.0 + 1.0) % 1.0;
                  final bounce = t < 0.5 ? t * 2 : (1 - t) * 2;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 7,
                    height: 7 + bounce * 5,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.6 + bounce * 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
