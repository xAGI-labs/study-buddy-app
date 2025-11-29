import 'package:flutter/material.dart';
import '../services/scraper_service.dart';
import '../services/ai_service.dart';

enum AppState { idle, scraping, summarizing, success, error }

class SummaryProvider extends ChangeNotifier {
  final ScraperService _scraper = ScraperService();
  final AIService _aiService = CactusAIService(); 

  AppState _state = AppState.idle;
  String? _summary;
  String? _errorMessage;
  String? _currentUrl;
  
  // State Management
  double _downloadProgress = 0.0;
  bool _isModelReady = false;
  bool _isChecking = true;      
  bool _isDownloading = false;
  bool _isMarkdownMode = false; 
  bool _isSlidesMode = false; // New state

  AppState get state => _state;
  String? get summary => _summary;
  String? get errorMessage => _errorMessage;
  double get downloadProgress => _downloadProgress;
  bool get isModelReady => _isModelReady;
  bool get isChecking => _isChecking;
  bool get isDownloading => _isDownloading;
  bool get isMarkdownMode => _isMarkdownMode;
  bool get isSlidesMode => _isSlidesMode;

  void toggleSlidesMode(bool value) {
    _isSlidesMode = value;
    if (value) _isMarkdownMode = false; // Mutually exclusive
    notifyListeners();
  }

  void toggleMarkdownMode(bool value) {
    _isMarkdownMode = value;
    if (value) _isSlidesMode = false; // Mutually exclusive
    notifyListeners();
  }

  // ... (Keep checkModelStatus and downloadModel as they were) ...
  Future<void> checkModelStatus() async {
    _isChecking = true;
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      _isModelReady = await _aiService.isModelDownloaded();
    } catch (e) {
      print("Error checking model status: $e");
      _isModelReady = false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<void> downloadModel() async {
    _isDownloading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _aiService.downloadModel((progress) {
        _downloadProgress = progress;
        notifyListeners();
      });
      _isModelReady = true;
      _isDownloading = false;
      notifyListeners();
    } catch (e) {
      _isDownloading = false;
      _errorMessage = "Download failed: $e";
      notifyListeners();
    }
  }

  // Existing URL Processor
  Future<void> processUrl(String url) async {
    if (url.isEmpty || (url == _currentUrl && _state == AppState.success)) return;
    
    _currentUrl = url;
    _state = AppState.scraping;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_isMarkdownMode) {
        // Direct HTML to Markdown conversion
        final markdown = await _scraper.fetchAndConvert(url);
        _summary = markdown;
        _state = AppState.success;
        notifyListeners();
      } else {
        // Standard Summarization Flow
        final cleanText = await _scraper.fetchAndClean(url);
        _processContent(cleanText); 
      }
    } catch (e) {
      _handleError(e);
    }
  }

  // NEW: Raw Text Processor
  Future<void> processText(String text) async {
    if (text.trim().isEmpty) return;
    if (text.length < 50 && !_isMarkdownMode) {
      _errorMessage = "Text is too short to summarize.";
      _state = AppState.error;
      notifyListeners();
      return;
    }

    _currentUrl = null; // Clear URL since this is raw text
    _state = AppState.summarizing; // Skip scraping state
    _errorMessage = null;
    notifyListeners();

    try {
      if (_isMarkdownMode) {
        final markdown = await _aiService.convertToMarkdown(text);
        _summary = markdown;
        _state = AppState.success;
        notifyListeners();
      } else {
        await _processContent(text);
      }
    } catch (e) {
      _handleError(e);
    }
  }

  // NEW: Slide Generator
  Future<void> generateSlides(String prompt) async {
    if (prompt.trim().isEmpty) return;
    
    _currentUrl = null;
    _state = AppState.summarizing;
    _errorMessage = null;
    notifyListeners();

    try {
      final slidesMarkdown = await _aiService.generateSlides(prompt);
      _summary = slidesMarkdown;
      _state = AppState.success;
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  // Helper to run AI on cleaned content
  Future<void> _processContent(String content) async {
    _state = AppState.summarizing;
    notifyListeners();

    final result = await _aiService.summarize(content);
    _summary = result;
    _state = AppState.success;
    notifyListeners();
  }

  void _handleError(dynamic e) {
    _errorMessage = e.toString();
    _state = AppState.error;
    _currentUrl = null;
    notifyListeners();
  }

  void reset() {
    _state = AppState.idle;
    _summary = null;
    _currentUrl = null;
    _errorMessage = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    if (_aiService is CactusAIService) {
      (_aiService as CactusAIService).dispose();
    }
    super.dispose();
  }
}