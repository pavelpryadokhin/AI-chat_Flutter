import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers/chat_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedProvider = 'OpenRouter';
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load API key from env or shared preferences
      final apiKey =
          dotenv.env['OPENROUTER_API_KEY'] ?? prefs.getString('API_KEY') ?? '';
      _apiKeyController.text = apiKey;

      // Load base URL from env or shared preferences
      final baseUrl = dotenv.env['BASE_URL'] ??
          prefs.getString('BASE_URL') ??
          'https://openrouter.ai/api/v1';
      _baseUrlController.text = baseUrl;

      // Load provider selection
      final provider = prefs.getString('PROVIDER') ?? 'OpenRouter';
      setState(() {
        _selectedProvider = provider;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Save API key
      await prefs.setString('API_KEY', _apiKeyController.text);

      // Save base URL
      await prefs.setString('BASE_URL', _baseUrlController.text);

      // Save provider selection
      await prefs.setString('PROVIDER', _selectedProvider);

      // Update environment variables
      dotenv.env['OPENROUTER_API_KEY'] = _apiKeyController.text;
      dotenv.env['BASE_URL'] = _baseUrlController.text;

      // Refresh the ChatProvider
      await context.read<ChatProvider>().refreshApiClient();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Настройки сохранены', style: TextStyle(fontSize: 12)),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error saving settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения: $e',
              style: const TextStyle(fontSize: 12)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки API', style: TextStyle(fontSize: 16)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Выберите провайдера API:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedProvider,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'OpenRouter',
                          child: Text('OpenRouter',
                              style: TextStyle(fontSize: 14)),
                        ),
                        DropdownMenuItem(
                          value: 'VSEGPT',
                          child: Text('VSEGPT', style: TextStyle(fontSize: 14)),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedProvider = value!;
                          if (value == 'OpenRouter') {
                            _baseUrlController.text =
                                'https://openrouter.ai/api/v1';
                          } else if (value == 'VSEGPT') {
                            _baseUrlController.text =
                                'https://api.vsegpt.ru/v1';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'API ключ:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _apiKeyController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Введите ваш API ключ',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 14),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите API ключ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Базовый URL:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _baseUrlController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Базовый URL API',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 14),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите базовый URL';
                        }
                        if (!Uri.tryParse(value)!.isAbsolute) {
                          return 'Пожалуйста, введите корректный URL';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text(
                          'Сохранить настройки',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
