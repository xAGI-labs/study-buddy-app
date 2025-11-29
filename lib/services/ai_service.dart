import 'package:cactus/cactus.dart';

abstract class AIService {
  Future<void> downloadModel(Function(double) onProgress);
  Future<bool> isModelDownloaded();
  Future<String> summarize(String articleText);
  Future<String> convertToMarkdown(String text);
  Future<String> generateSlides(String prompt);
}

class CactusAIService implements AIService {
  final CactusLM _lm = CactusLM(enableToolFiltering: false);
  static const String _modelSlug = "gemma3-270m"; 
  bool _isInitialized = false;

  @override
  Future<bool> isModelDownloaded() async {
    final models = await _lm.getModels();
    // Check if our specific model is marked as downloaded
    return models.any((m) => m.slug == _modelSlug && m.isDownloaded);
  }

  @override
  Future<void> downloadModel(Function(double) onProgress) async {
    print("Cactus: Starting download for $_modelSlug...");
    
    await _lm.downloadModel(
      model: _modelSlug,
      downloadProcessCallback: (progress, status, isError) {
        if (progress != null) {
          onProgress(progress);
        }
      },
    );

    // Initialize immediately after download
    if (!_isInitialized) {
      await _lm.initializeModel(
        params: CactusInitParams(model: _modelSlug, contextSize: 2048),
      );
      _isInitialized = true;
    }
  }

  @override
  Future<String> summarize(String articleText) async {
    if (!_isInitialized) {
      // Fallback initialization if skipped (shouldn't happen with new flow)
      await _lm.initializeModel(
        params: CactusInitParams(model: _modelSlug, contextSize: 2048),
      );
      _isInitialized = true;
    }

    final result = await _lm.generateCompletion(
      messages: [
        ChatMessage(
          role: "user", 
          content: "Summarize the following news article in a clear, professional executive brief. Use bullet points for key takeaways:\n\n$articleText"
        ),
      ],
      params: CactusCompletionParams(
        maxTokens: 512,
        temperature: 0.7,
        stopSequences: ["<end_of_turn>", "<|im_end|>"],
      ),
    );

    if (!result.success) throw Exception("Generation failed: ${result.response}");
    return result.response;
  }

  @override
  Future<String> convertToMarkdown(String text) async {
    if (!_isInitialized) {
      await _lm.initializeModel(
        params: CactusInitParams(model: _modelSlug, contextSize: 2048),
      );
      _isInitialized = true;
    }

    final result = await _lm.generateCompletion(
      messages: [
        ChatMessage(
          role: "user", 
          content: "Convert the following text to clean, well-formatted Markdown:\n\n$text"
        ),
      ],
      params: CactusCompletionParams(
        maxTokens: 1024,
        temperature: 0.3,
        stopSequences: ["<end_of_turn>", "<|im_end|>"],
      ),
    );

    if (!result.success) throw Exception("Conversion failed: ${result.response}");
    return result.response;
  }

  @override
  Future<String> generateSlides(String prompt) async {
    if (!_isInitialized) {
      await _lm.initializeModel(
        params: CactusInitParams(model: _modelSlug, contextSize: 2048),
      );
      _isInitialized = true;
    }

    final fullPrompt = """
Create a 5-slide presentation on the following topic: "$prompt".
Format the output as Markdown compatible with SuperDeck.
Follow these rules strictly:
1. Use '---' to separate slides.
2. The first slide should be a title slide.
3. Use '@column' to structure content.
4. Use '#' for titles and '-' for bullet points.
5. Do not include any other text or explanations, only the Markdown.

Example format:
---
@column
# Title
- Point 1
- Point 2
---
@column
# Slide 2
- Detail 1
- Detail 2
---
""";

    final result = await _lm.generateCompletion(
      messages: [
        ChatMessage(role: "user", content: fullPrompt),
      ],
      params: CactusCompletionParams(
        maxTokens: 1024,
        temperature: 0.7,
        stopSequences: ["<end_of_turn>", "<|im_end|>"],
      ),
    );

    if (!result.success) throw Exception("Slide generation failed: ${result.response}");
    return result.response;
  }
  
  void dispose() {
    _lm.unload();
  }
}