import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/watchlist_screen.dart';

class BottomNavBar extends StatelessWidget {
  final BuildContext parentContext; // Needed for navigation
  final VoidCallback? onHomeTap; // Optional callback to refresh Home
  final VoidCallback? onAccountTap; // Optional callback to open account menu

  const BottomNavBar({
    super.key,
    required this.parentContext,
    this.onHomeTap,
    this.onAccountTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color navy = Color(0xFF0D1B2A);
    const Color orange = Color(0xFFEB8908);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: navy,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// HOME
          GestureDetector(
            onTap: () {
              if (onHomeTap != null) {
                // If parent wants to refresh HomeScreen instead of navigation
                onHomeTap!();
              } else {
                // Navigate to HomeScreen and replace current screen to avoid stacking
                Navigator.pushReplacement(
                  parentContext,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.home, color: orange),
                SizedBox(height: 4),
                Text(
                  "Home",
                  style: TextStyle(color: orange, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          /// WATCHLIST
          GestureDetector(
            onTap: () {
              // Only push if not already on Watchlist
              final routeIsWatchlist =
                  ModalRoute.of(parentContext)?.settings.name == '/watchlist';
              if (!routeIsWatchlist) {
                Navigator.push(
                  parentContext,
                  MaterialPageRoute(builder: (_) => const WatchlistScreen()),
                );
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.favorite, color: orange),
                SizedBox(height: 4),
                Text(
                  "Watchlist",
                  style: TextStyle(color: orange, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          /// ACCOUNT MENU
          GestureDetector(
            onTap: onAccountTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.more_vert, color: orange),
                SizedBox(height: 4),
                Text(
                  "Account",
                  style: TextStyle(color: orange, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
