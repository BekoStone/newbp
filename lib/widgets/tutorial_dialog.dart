import 'package:flutter/material.dart';
import '../services/game_storage.dart';
import '../services/analytics_service.dart';

class TutorialDialog extends StatefulWidget {
  const TutorialDialog({super.key});

  @override
  State<TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<TutorialDialog> {
  int currentPage = 0;
  final PageController _pageController = PageController();

  final List<TutorialPage> tutorialPages = [
    TutorialPage(
      title: "Welcome to Block Puzzle!",
      description: "Drag and drop blocks to fill rows and columns",
      icon: Icons.grid_view,
      color: Colors.blue,
    ),
    TutorialPage(
      title: "Clear Lines",
      description: "Fill complete rows or columns to clear them and score points",
      icon: Icons.horizontal_rule,
      color: Colors.green,
    ),
    TutorialPage(
      title: "Build Combos",
      description: "Clear multiple lines in succession for combo multipliers!",
      icon: Icons.whatshot,
      color: Colors.orange,
    ),
    TutorialPage(
      title: "Use Power-ups",
      description: "Use Clear, Blast, and Shuffle power-ups strategically",
      icon: Icons.bolt,
      color: Colors.purple,
    ),
    TutorialPage(
      title: "Watch Ads for Rewards",
      description: "Watch ads to get extra power-ups when you run out",
      icon: Icons.play_circle_filled,
      color: Colors.red,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (currentPage < tutorialPages.length - 1) {
      setState(() {
        currentPage++;
      });
      _pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeTutorial();
    }
  }

  void _previousPage() {
    if (currentPage > 0) {
      setState(() {
        currentPage--;
      });
      _pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeTutorial() async {
    await GameStorage.instance.setTutorialShown();
    await AnalyticsService.instance.logTutorialCompleted();
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _skipTutorial() async {
    await GameStorage.instance.setTutorialShown();
    await AnalyticsService.instance.logEvent('tutorial_skipped', {
      'skipped_at_page': currentPage,
    });
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEFD5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tutorial',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: _skipTutorial,
                    icon: const Icon(Icons.close, color: Colors.black54),
                  ),
                ],
              ),
            ),
            
            // Page indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  tutorialPages.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == currentPage
                          ? Colors.blue
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Tutorial content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                itemCount: tutorialPages.length,
                itemBuilder: (context, index) {
                  final page = tutorialPages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: page.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: page.color,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            page.icon,
                            size: 60,
                            color: page.color,
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        Text(
                          page.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        Text(
                          page.description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  currentPage > 0
                      ? ElevatedButton.icon(
                          onPressed: _previousPage,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Previous'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black87,
                          ),
                        )
                      : const SizedBox(width: 100),
                  
                  // Skip button
                  TextButton(
                    onPressed: _skipTutorial,
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  
                  // Next/Finish button
                  ElevatedButton.icon(
                    onPressed: _nextPage,
                    icon: Icon(
                      currentPage == tutorialPages.length - 1
                          ? Icons.check
                          : Icons.arrow_forward,
                    ),
                    label: Text(
                      currentPage == tutorialPages.length - 1
                          ? 'Start '
                          : 'Next',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TutorialPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  TutorialPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// Helper function to show tutorial if needed
Future<void> showTutorialIfNeeded(BuildContext context) async {
  final hasShownTutorial = await GameStorage.instance.isTutorialShown();
  
  if (!hasShownTutorial && context.mounted) {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const TutorialDialog(),
      );
    }
  }
}