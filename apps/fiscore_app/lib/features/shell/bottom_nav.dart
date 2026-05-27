part of '../../main.dart';

class _FiScoreBottomNav extends StatelessWidget {
  const _FiScoreBottomNav({
    required this.siteCount,
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
  });

  final int siteCount;
  final int selectedIndex;
  final ValueChanged<int> onSelectedIndexChanged;

  @override
  Widget build(BuildContext context) {
    final appIndexes = [1, 2, 3, 4, 5];
    final navIndex = appIndexes.contains(selectedIndex)
        ? appIndexes.indexOf(selectedIndex)
        : appIndexes.indexOf(1);
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(Icons.report_problem_outlined),
        selectedIcon: Icon(Icons.report_problem),
        label: 'Violations',
      ),
      const NavigationDestination(
        icon: Icon(Icons.playlist_add_check_circle_outlined),
        selectedIcon: Icon(Icons.playlist_add_check_circle),
        label: 'Audits',
      ),
      const NavigationDestination(
        icon: Icon(Icons.school_outlined),
        selectedIcon: Icon(Icons.school),
        label: 'Training',
      ),
      const NavigationDestination(
        icon: Icon(Icons.more_horiz),
        selectedIcon: Icon(Icons.more),
        label: 'More',
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14071A4A),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: NavigationBar(
        height: 68,
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: _softGreen,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: navIndex,
        onDestinationSelected: (index) {
          onSelectedIndexChanged(appIndexes[index]);
        },
        destinations: destinations,
      ),
    );
  }
}
