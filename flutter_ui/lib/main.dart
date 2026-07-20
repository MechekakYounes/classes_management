import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'screens/dashboard_screen.dart';
import 'screens/student_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/wilaya_list_screen.dart';
import 'screens/baladiya_management_screen.dart';
import 'screens/groups_screen.dart';
import 'screens/sessions_screen.dart';
import 'auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().init();
  runApp(const ClassManagerApp());
}

class ClassManagerApp extends StatelessWidget {
  const ClassManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Class Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFE0F7FA),
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        appBarTheme: AppBarTheme(
          toolbarHeight: 65,
          backgroundColor: Colors.cyan,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan.shade600,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class MainTabController extends StatefulWidget {
  final int? communeId;
  const MainTabController({super.key, this.communeId});

  @override
  State<MainTabController> createState() => _MainTabControllerState();
}

class _MainTabControllerState extends State<MainTabController> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;
  final GlobalKey<NavigatorState> _dashboardNavigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    final auth = AuthService();
    Widget dashboardWidget;

    if (widget.communeId != null) {
      dashboardWidget = DashboardScreen(communeId: widget.communeId);
    } else if (auth.isSuperAdmin()) {
      dashboardWidget = const WilayaListScreen();
    } else if (auth.isAdmin()) {
      final wilayaId = auth.wilayaId ?? 16;
      dashboardWidget = BaladiyaManagementScreen(
        wilayaId: wilayaId,
        wilayaName: auth.wilayaName ?? "الجزائر",
      );
    } else if (auth.isSupervisor()) {
      dashboardWidget = DashboardScreen(communeId: auth.communeId ?? widget.communeId);
    } else if (auth.isManager()) {
      dashboardWidget = GroupsScreen(
        className: auth.user?['class']?['name'] ?? "المدرسة المعينة",
        classId: auth.classId ?? 1,
      );
    } else if (auth.isTeacher()) {
      dashboardWidget = SessionScreen(
        groupId: auth.groupId ?? 1,
        groupName: auth.user?['group']?['name'] ?? "القسم المعين",
      );
    } else {
      dashboardWidget = DashboardScreen(communeId: widget.communeId);
    }

    _screens = [
      Navigator(
        key: _dashboardNavigatorKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => dashboardWidget,
            settings: settings,
          );
        },
      ),
      const StudentsScreen(),
      const ProfileScreen(),
    ];
  }

  void _onTabTapped(int index) {
    if (index == 0) {
      _dashboardNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      setState(() {
        _selectedIndex = 0;
      });
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: SizedBox(
        height: 100,
        child: Stack(
          children: [
            // Wave background
            Positioned.fill(
              child: CustomPaint(
                painter: WavePainter(),
              ),
            ),
            // Icons in nav bar
            Align(
              alignment: Alignment.center,
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onTabTapped,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white70,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(FontAwesomeIcons.home),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FontAwesomeIcons.users),
                    label: 'Students',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FontAwesomeIcons.gear),
                    label: 'Settings',
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

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.moveTo(0, 10);
    path.quadraticBezierTo(size.width / 4, 0, size.width / 2, 12);
    path.quadraticBezierTo(size.width * 3 / 4, 24, size.width, 10);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
