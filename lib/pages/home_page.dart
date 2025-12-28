import 'package:flutter/material.dart';
import 'package:onecummins/constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isCollapsed = true;

  void _openAiFlow() {
    Navigator.pushNamed(context, '/login', arguments: {"redirect": "/ai_chat"});
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final bool isMobile = width < 900;

    return Scaffold(
      backgroundColor: AppColors.bgLight,

      // Drawer only for mobile
      drawer: isMobile ? _buildMobileDrawer() : null,

      appBar: isMobile
          ? AppBar(
              elevation: 0,
              title: const Text("OneCummins"),
              backgroundColor: AppColors.teal,
            )
          : null,

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgLight, Color(0xFFEFFDFB)],
          ),
        ),

        // ---- SWITCH LAYOUT BASED ON SCREEN SIZE ----
        child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
    );
  }

  // ---------------- DESKTOP UI (UNCHANGED) ----------------
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: MouseRegion(
            onEnter: (_) => setState(() => isCollapsed = false),
            onExit: (_) => setState(() => isCollapsed = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isCollapsed ? 80 : 200,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 28),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    height: isCollapsed ? 42 : 80,
                    width: isCollapsed ? 42 : 80,
                    child: Image.asset('images/logo.png', fit: BoxFit.contain),
                  ),

                  const SizedBox(height: 48),

                  SidebarIcon(
                    icon: Icons.smart_toy_outlined,
                    title: "AI Help",
                    isCollapsed: isCollapsed,
                    onTap: _openAiFlow,
                  ),
                  SidebarIcon(
                    icon: Icons.login,
                    title: "Login",
                    isCollapsed: isCollapsed,
                    onTap: () => Navigator.pushNamed(context, '/login'),
                  ),
                  SidebarIcon(
                    icon: Icons.app_registration,
                    title: "Register",
                    isCollapsed: isCollapsed,
                    onTap: () => Navigator.pushNamed(context, '/register'),
                  ),
                  const Spacer(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: _mainContent(),
          ),
        ),
      ],
    );
  }

  // ---------------- MOBILE LAYOUT ----------------
  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row
            Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Welcome to OneCummins',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Public Access',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // AI Hero (same style but compact)
            _aiHero(),

            const SizedBox(height: 22),

            // AI Preview
            _aiPreviewCard(),

            const SizedBox(height: 18),

            // Features Section stacked vertically
            _featuresCard(),
          ],
        ),
      ),
    );
  }

  // ---------------- MOBILE DRAWER ----------------
  Widget _buildMobileDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const SizedBox(height: 10),

            Center(child: Image.asset('images/logo.png', height: 70)),

            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(
                Icons.smart_toy_outlined,
                color: AppColors.teal,
              ),
              title: const Text("AI Help"),
              onTap: _openAiFlow,
            ),

            ListTile(
              leading: const Icon(Icons.login, color: AppColors.teal),
              title: const Text("Login"),
              onTap: () => Navigator.pushNamed(context, '/login'),
            ),

            ListTile(
              leading: const Icon(
                Icons.app_registration,
                color: AppColors.teal,
              ),
              title: const Text("Register"),
              onTap: () => Navigator.pushNamed(context, '/register'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- REUSABLE CONTENT UI ----------------

  Widget _mainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Welcome to OneCummins',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Public Access',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),

        _aiHero(),

        const SizedBox(height: 40),

        Expanded(
          child: Row(
            children: [
              Expanded(flex: 2, child: _aiPreviewCard()),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: _featuresCard()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _aiHero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [AppColors.teal, AppColors.purple.withOpacity(0.85)],
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ask anything about your college',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Events • Notices • Clubs • Deadlines',
            style: TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 14),

          ElevatedButton.icon(
            onPressed: _openAiFlow,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.smart_toy_outlined),
            label: const Text(
              "Ask with AI Assistant",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "AI Assistant Preview",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 12),

          // Chat preview background
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(18),
            ),

            child: Column(
              children: const [

                ChatBubble(
                  isUser: true,
                  text: "When is the exam form submission deadline?",
                ),
                ChatBubble(
                  isUser: false,
                  text: "Exam form submission closes on 5 Feb, 3:00 PM.",
                ),

                ChatBubble(
                  isUser: true,
                  text: "Show upcoming technical events",
                ),
                ChatBubble(
                  isUser: false,
                  text: "2 upcoming events — Robotics Workshop & Hackathon.",
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // CTA button (Explore / Continue AI)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _openAiFlow,
              icon: const Icon(Icons.smart_toy_outlined),
              label: const Text("Continue with AI"),
            ),
          ),
        ],
      ),
    );
  }


  Widget _featuresCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "What our app can do",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),

          SizedBox(height: 12),

          FeaturePoint(
            icon: Icons.event_available,
            text: "View college events & activities",
          ),
          FeaturePoint(
            icon: Icons.campaign_outlined,
            text: "Access important notices & updates",
          ),
          FeaturePoint(
            icon: Icons.groups_2_outlined,
            text: "Connect with clubs & communities",
          ),
          FeaturePoint(
            icon: Icons.dashboard_customize_outlined,
            text: "Role–based dashboards for users",
          ),
          FeaturePoint(
            icon: Icons.smart_toy_outlined,
            text: "Ask questions using AI Assistant",
          ),
        ],
      ),
    );
  }
}

// ---------------- SIDEBAR ITEM ----------------
class SidebarIcon extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isCollapsed;
  final VoidCallback? onTap;

  const SidebarIcon({
    super.key,
    required this.icon,
    required this.title,
    required this.isCollapsed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          mainAxisAlignment: isCollapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            const SizedBox(width: 12),
            Icon(icon, color: AppColors.teal),

            if (!isCollapsed) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------- CHAT BUBBLE ----------------
class ChatBubble extends StatelessWidget {
  final bool isUser;
  final String text;

  const ChatBubble({super.key, required this.isUser, required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.teal : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : AppColors.textDark),
        ),
      ),
    );
  }
}

// ---------------- FEATURE POINT TILE ----------------
class FeaturePoint extends StatelessWidget {
  final IconData icon;
  final String text;

  const FeaturePoint({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
