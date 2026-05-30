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
    final strings = AppLocalizations.of(context);
    final appIndexes = [1, 2, 3, 4, 5];
    final navIndex = appIndexes.contains(selectedIndex)
        ? appIndexes.indexOf(selectedIndex)
        : appIndexes.indexOf(1);
    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: strings.home,
      ),
      NavigationDestination(
        icon: const Icon(Icons.report_problem_outlined),
        selectedIcon: const Icon(Icons.report_problem),
        label: strings.violations,
      ),
      NavigationDestination(
        icon: const Icon(Icons.playlist_add_check_circle_outlined),
        selectedIcon: const Icon(Icons.playlist_add_check_circle),
        label: strings.audits,
      ),
      NavigationDestination(
        icon: const Icon(Icons.school_outlined),
        selectedIcon: const Icon(Icons.school),
        label: strings.training,
      ),
      NavigationDestination(
        icon: const Icon(Icons.more_horiz),
        selectedIcon: const Icon(Icons.more),
        label: strings.more,
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
