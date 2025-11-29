import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

class SlidesScreen extends StatefulWidget {
  final String markdownContent;

  const SlidesScreen({super.key, required this.markdownContent});

  @override
  State<SlidesScreen> createState() => _SlidesScreenState();
}

class _SlidesScreenState extends State<SlidesScreen> {
  late List<String> _slides;
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _parseSlides();
  }

  void _parseSlides() {
    // Split by horizontal rule '---'
    // Normalize newlines first
    // Split by horizontal rule '---' with optional newlines and whitespace
    final content = widget.markdownContent.replaceAll('\r\n', '\n');
    _slides = content.split(RegExp(r'\n\s*---\s*\n?')).where((s) => s.trim().isNotEmpty).toList();
    
    if (_slides.isEmpty) {
      _slides = ["# No slides generated\n\nPlease try again."];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Slide ${_currentIndex + 1} / ${_slides.length}",
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _slides.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return _buildSlide(_slides[index]);
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white54),
              onPressed: _currentIndex > 0 
                ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                : null,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
              onPressed: _currentIndex < _slides.length - 1
                ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(String content) {
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: MarkdownBody(
            data: content,
            styleSheet: MarkdownStyleSheet(
              h1: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              h2: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: const Color(0xFFA855F7)), // Purple accent
              h3: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white70),
              p: GoogleFonts.inter(fontSize: 18, color: Colors.white70, height: 1.5),
              listBullet: GoogleFonts.inter(fontSize: 18, color: const Color(0xFFA855F7)),
              blockquote: GoogleFonts.inter(fontSize: 16, color: Colors.grey, fontStyle: FontStyle.italic),
              code: GoogleFonts.firaCode(fontSize: 14, backgroundColor: Colors.black54),
            ),
          ),
        ),
      ),
    );
  }
}
