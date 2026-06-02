// ─── home_screen.dart ─────────────────────────────────────────────────────────
// The HomeScreen is the main navigation container for the ClimaTalk app.
// It hosts four tabs using an IndexedStack and a custom bottom navigation bar.
//
// Tabs:
//   0 - Home     → Current weather for user's location
//   1 - Forecast → 7-day forecast screen
//   2 - AI Chat  → AI chatbot screen
//   3 - Saved    → Saved favorite cities
//
// Architecture:
//   - HomeScreen: The shell/container with IndexedStack + bottom nav
//   - _HomeTab: The actual weather content of tab 0
//   - _NavItem: Individual bottom nav button with animations
//   - _QuickActions: Row of shortcut cards on the home tab
//   - _ActionCard: Individual animated shortcut card

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../providers/weather_provider.dart';
import '../providers/forecast_provider.dart';

import '../widgets/weather_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/app_error_widget.dart';
import 'forecast_screen.dart';
import 'chat_screen.dart';
import 'saved_cities_screen.dart';

import 'settings_screen.dart';

// ─── HomeScreen (Shell) ───────────────────────────────────────────────────────
// Manages which tab is active and renders it inside a FadeTransition for
// smooth screen switching. TickerProviderStateMixin enables the nav animation.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0; // Index of the currently active tab
  late AnimationController _navController;
  late Animation<double> _navFadeAnim;
  late List<Widget> _screens; // The four tab screens (created once in initState)

  @override
  void initState() {
    super.initState();
    // Animation for tab switching — fades from old tab to new tab.
    _navController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _navFadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _navController, curve: Curves.easeIn));
    _navController.forward();

    // Build screens once — avoids re-instantiating widgets on every build call.
    // IndexedStack keeps all screens alive in the widget tree, but only shows one.
    // This preserves each screen's scroll position and state when switching tabs.
    _screens = [
      _HomeTab(onTabChange: _onTabTapped),
      const ForecastScreen(),
      const ChatScreen(),
      const SavedCitiesScreen(),
    ];

    // Fetch weather immediately after the widget tree is built.
    // Future.microtask defers until after initState() completes.
    Future.microtask(
      () => ref.read(weatherProvider.notifier).fetchWeatherByLocation(),
    );
  }

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  // Called when the user taps a navigation item.
  // Resets and re-plays the fade animation for smooth visual feedback.
  void _onTabTapped(int index) {
    if (_selectedIndex == index) return; // No-op if already on this tab
    _navController.reset();
    setState(() => _selectedIndex = index);
    _navController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // FadeTransition wraps the IndexedStack to animate tab changes.
      // IndexedStack: renders all screens but only shows one at a time.
      body: FadeTransition(
        opacity: _navFadeAnim,
        child: IndexedStack(index: _selectedIndex, children: _screens),
      ),
      bottomNavigationBar: _buildBeautifulBottomNav(),
    );
  }

  // ─── Custom Bottom Navigation Bar ─────────────────────────────────────────
  // A handcrafted nav bar instead of Flutter's default BottomNavigationBar,
  // allowing full visual control including gradient highlights and scale effects.
  Widget _buildBeautifulBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4), // Shadow above the nav bar
          ),
        ],
      ),
      child: SafeArea(
        top: false, // SafeArea adds padding only at the bottom for device insets
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                selectedIndex: _selectedIndex,
                onTap: _onTabTapped,
              ),
              _NavItem(
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today_rounded,
                label: 'Forecast',
                index: 1,
                selectedIndex: _selectedIndex,
                onTap: _onTabTapped,
              ),
              _NavItem(
                icon: Icons.smart_toy_outlined,
                activeIcon: Icons.smart_toy_rounded,
                label: 'AI Chat',
                index: 2,
                selectedIndex: _selectedIndex,
                onTap: _onTabTapped,
              ),
              _NavItem(
                icon: Icons.bookmark_border_rounded,
                activeIcon: Icons.bookmark_rounded,
                label: 'Saved',
                index: 3,
                selectedIndex: _selectedIndex,
                onTap: _onTabTapped,
              ),

            ],
          ),
        ),
      ),
    );
  }
}

// ─── _NavItem ─────────────────────────────────────────────────────────────────
// A single animated navigation button in the bottom bar.
// When selected, the icon scales up with a bounce effect.
class _NavItem extends StatefulWidget {
  final IconData icon;       // Icon when not selected
  final IconData activeIcon; // Icon when selected (filled variant)
  final String label;        // Text label below the icon
  final int index;           // This button's tab index
  final int selectedIndex;   // Currently active tab index
  final Function(int) onTap; // Callback to switch tabs

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    // A short animation that briefly scales the icon up and back down on selection.
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(
      begin: 1,
      end: 1.2, // Scale up to 120% briefly
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    // Trigger the scale animation ONLY when this specific item becomes selected.
    if (widget.selectedIndex == widget.index &&
        old.selectedIndex != widget.index) {
      _ctrl.forward().then((_) => _ctrl.reverse()); // Scale up then back down
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedIndex == widget.index;
    return GestureDetector(
      onTap: () => widget.onTap(widget.index),
      behavior: HitTestBehavior.opaque, // Makes the whole padding area tappable
      child: ScaleTransition(
        scale: _scaleAnim,
        // AnimatedContainer smoothly transitions background color on selection.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryBlue.withValues(alpha: 0.1) // Highlight background
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AnimatedSwitcher crossfades between the outlined and filled icon.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? widget.activeIcon : widget.icon,
                  key: ValueKey(isSelected), // Required for AnimatedSwitcher to detect change
                  color: isSelected ? AppTheme.primaryBlue : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              // AnimatedDefaultTextStyle smoothly transitions label font weight and color.
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? AppTheme.primaryBlue : Colors.grey,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── _HomeTab ─────────────────────────────────────────────────────────────────
// The content of tab index 0. Shows the current weather card and quick actions.
// Has a search bar in the AppBar for manual city lookup.
class _HomeTab extends ConsumerStatefulWidget {
  final void Function(int index) onTabChange;
  const _HomeTab({required this.onTabChange});

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false; // Toggles between title text and search text field
  late AnimationController _searchAnim;

  @override
  void initState() {
    super.initState();
    _searchAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchAnim.dispose();
    super.dispose();
  }

  // Called when the user submits the city search query.
  // Triggers both weather AND forecast fetches for the new city.
  void _handleSearch() {
    final q = _searchController.text.trim();
    if (q.isNotEmpty) {
      ref.read(weatherProvider.notifier).fetchWeatherByCity(q);
      ref.read(forecastProvider.notifier).fetchForecastByCity(q);
      setState(() => _showSearch = false); // Close the search field
      _searchController.clear();
      FocusScope.of(context).unfocus(); // Dismiss keyboard
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherState = ref.watch(weatherProvider);
    final theme = Theme.of(context);

    // ref.listen is a side-effect listener — it runs the callback whenever
    // weatherProvider state changes WITHOUT causing a widget rebuild.
    // Here we use it to automatically fetch the forecast when weather city changes.
    ref.listen<WeatherState>(weatherProvider, (prev, current) {
      if (current.hasData && current.weather != null) {
        // Guard: skip redundant downstream fetches when the city hasn't changed.
        final prevCity = prev?.weather?.cityName;
        final newCity = current.weather!.cityName;
        if (prevCity == newCity) return;

        // Automatically load the forecast for the newly selected city.
        ref
            .read(forecastProvider.notifier)
            .fetchForecastByCoords(
              current.weather!.latitude,
              current.weather!.longitude,
            );
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          // Switches between the app title and the search input field.
          child: _showSearch
              ? TextField(
                  key: const ValueKey('search'),
                  controller: _searchController,
                  autofocus: true, // Keyboard opens automatically
                  decoration: InputDecoration(
                    hintText: 'Search city...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  onSubmitted: (_) => _handleSearch(),
                )
              : const Text('ClimaTalk', key: ValueKey('title')),
        ),
        actions: [
          // Search/Close toggle button
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _showSearch ? Icons.close_rounded : Icons.search_rounded,
                key: ValueKey(_showSearch),
              ),
            ),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) _searchController.clear();
            }),
          ),
          // Settings button — navigates to SettingsScreen
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      // ─── Body ─────────────────────────────────────────────────────────────
      // RefreshIndicator adds pull-to-refresh functionality.
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(weatherProvider.notifier).fetchWeatherByLocation(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Greeting Header ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: Row(
                      children: [
                        // Gradient avatar/badge with wave emoji
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text('👋',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, Explorer 👋',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "Today's Weather",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ─── Weather Content (Conditional) ────────────────────────
                  // Shows different UI based on the current state of weatherProvider.
                  if (weatherState.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: LoadingWidget(message: 'Fetching weather...'),
                    )
                  else if (weatherState.hasError)
                    AppErrorWidget(
                      message: weatherState.errorMessage!,
                      onRetry: () => ref
                          .read(weatherProvider.notifier)
                          .fetchWeatherByLocation(),
                    )
                  else if (weatherState.hasData)
                    WeatherCard(
                      weather: weatherState.weather!,
                      onRefresh: () => ref
                          .read(weatherProvider.notifier)
                          .fetchWeatherByLocation(),
                    )
                  else
                    _buildEmptyState(context), // Initial state — no data yet

                  // ─── Quick Actions Section (only when weather is loaded) ──
                  if (weatherState.hasData) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text(
                        'Quick Actions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _QuickActions(onTabChange: widget.onTabChange),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shown when the app first loads and no weather is available yet.
  // Prompts the user to search or allow location access.
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 40,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Search a city or allow\nlocation access to get started',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── _QuickActions ────────────────────────────────────────────────────────────
// A row of three shortcut cards that navigate to other tabs.
// Displayed on the Home tab after weather data loads successfully.
class _QuickActions extends StatelessWidget {
  final void Function(int) onTabChange;
  const _QuickActions({required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              icon: Icons.calendar_today_rounded,
              label: '7-Day\nForecast',
              gradient: const [Color(0xFF1565C0), Color(0xFF42A5F5)],
              onTap: () => onTabChange(1), // Navigate to Forecast tab
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionCard(
              icon: Icons.smart_toy_rounded,
              label: 'AI\nAssistant',
              gradient: const [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
              onTap: () => onTabChange(2), // Navigate to AI Chat tab
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionCard(
              icon: Icons.bookmark_add_rounded,
              label: 'Saved\nCities',
              gradient: const [Color(0xFFE65100), Color(0xFFFF8C00)],
              onTap: () => onTabChange(3), // Navigate to Saved Cities tab
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _ActionCard ──────────────────────────────────────────────────────────────
// An individual gradient card with an icon and label.
// Has a "press down" scale animation (shrinks to 95% when tapped) for
// a tactile, physical button feel.
class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    // Short press animation: scale from 1.0 down to 0.95 and back.
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(
      begin: 1,
      end: 0.95, // Shrink slightly on tap for tactile feedback
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),    // Start shrinking on press
      onTapUp: (_) {
        _ctrl.reverse();                    // Restore size on release
        widget.onTap();                     // Then trigger the navigation
      },
      onTapCancel: () => _ctrl.reverse(),  // Restore size if press is cancelled
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                // Shadow color matches the card gradient for a "glow" effect.
                color: widget.gradient.first.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(widget.icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
