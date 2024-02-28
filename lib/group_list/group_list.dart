import 'package:flutter/material.dart';
import 'package:positioned_scroll_observer/positioned_scroll_observer.dart';

class GroupObservers {
  final SliverScrollObserver titleObserver;
  final SliverScrollObserver itemObserver;

  GroupObservers({required this.itemObserver, required this.titleObserver});

  void clear() {
    titleObserver.clear();
    itemObserver.clear();
  }
}

class GroupList extends StatefulWidget {
  const GroupList({super.key});

  @override
  State<GroupList> createState() => _GroupListState();
}

class _GroupListState extends State<GroupList> {
  final ScrollController _controller = ScrollController();

  final List<String> _groups = ["Group A", "Group B", "Group C", "Group D"];
  final List<int> _groupCounts = [30, 20, 15, 40];

  late final ValueNotifier<int> _selectedIndex = ValueNotifier(0);

  final Map<int, GroupObservers> _observers = {};
  @override
  void initState() {
    super.initState();

    for (int i = 0; i < _groups.length; i++) {
      _observers[i] = GroupObservers(
        titleObserver: ScrollObserver.sliverSingle(),
        itemObserver: ScrollObserver.sliverMulti(itemCount: _groupCounts[i]),
      );
    }

    _controller.addListener(_listenScroll);
    _selectedIndex.addListener(_listenIndexChange);
  }

  @override
  void dispose() {
    for (final groupObserver in _observers.values) {
      groupObserver.clear();
    }
    _controller.removeListener(_listenScroll);
    _selectedIndex.removeListener(_listenIndexChange);
    _controller.dispose();
    _selectedIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GroupListTabBar(
          tabCount: _groups.length,
          tabBuilder: (_, index) => _buildTab(index),
          selected: _selectedIndex,
        ),
        Expanded(
          child: CustomScrollView(
            controller: _controller,
            slivers: [
              for (int i = 0; i < _groups.length; i++) ..._buildSubList(i),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTab(int index) {
    return Text(
      _groups[index],
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: _selectedIndex.value == index ? Colors.red : Colors.black,
      ),
    );
  }

  List<Widget> _buildSubList(int index) {
    final title = _buildGroupTitle(index);
    final list = SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, itemIndex) => _buildGroupItem(index, itemIndex),
        childCount: _groupCounts[index],
      ),
    );
    return [title, list];
  }

  Widget _buildGroupTitle(int index) {
    return SliverToBoxAdapter(
      child: ObserverProxy(
        observer: _observers[index]!.titleObserver,
        child: Center(
          child: Text(
            _groups[index],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupItem(int groupIndex, int itemIndex) {
    return ObserverProxy(
      observer: _observers[groupIndex]!.itemObserver,
      child: ListTile(
        title: Text("${_groups[groupIndex]}: $itemIndex"),
      ),
    );
  }

  void _listenIndexChange() {
    _observers[_selectedIndex.value]?.titleObserver.showInViewport(
          _controller.position,
          duration: const Duration(milliseconds: 300),
        );

    // final titleObserver = _observers[_selectedIndex.value]!.titleObserver;

    // _controller.jumpTo(titleObserver.origin!.offset);

    // _controller.position.ensureVisible(
    //   titleObserver.renderObject!,
    // );

    // _observers[_selectedIndex.value]?.itemObserver.animateToIndex(
    //       0,
    //       position: _controller.position,
    //       duration: const Duration(milliseconds: 300),
    //       curve: Curves.linear,
    //     );
  }

  void _listenScroll() {
    print("scroll to ${_selectedIndex.value}");
    final groupObserver = _observers[_selectedIndex.value]!;

    // if (!groupObserver.titleObserver.renderVisible) {
    //   for (final index in _observers.keys) {
    //     final groupObserver = _observers[index]!;

    //     if (groupObserver.titleObserver.renderVisible) {
    //       _selectedIndex.value = index;
    //       break;
    //     }
    //   }
    // }
  }
}

class GroupListTabBar extends StatefulWidget {
  final int tabCount;
  final IndexedWidgetBuilder tabBuilder;
  final ValueNotifier<int> selected;
  const GroupListTabBar({
    super.key,
    required this.tabCount,
    required this.tabBuilder,
    required this.selected,
  });

  @override
  State<GroupListTabBar> createState() => _GroupListTabBarState();
}

class _GroupListTabBarState extends State<GroupListTabBar>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(
    length: widget.tabCount,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    widget.selected.addListener(_onIndexChange);
  }

  void _select(int index) {
    widget.selected.value = index;
  }

  void _onIndexChange() {
    print("current tab: ${widget.selected.value}");
    _controller.animateTo(
      widget.selected.value,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.selected.removeListener(_onIndexChange);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: _controller,
      isScrollable: true,
      indicator: const BoxDecoration(),
      tabs: List.generate(
        widget.tabCount,
        (index) => ValueListenableBuilder(
          valueListenable: widget.selected,
          builder: (_, selected, child) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: selected == index ? Colors.green : Colors.grey,
              ),
              child: widget.tabBuilder(_, index),
            );
          },
        ),
      ),
      onTap: _select,
    );
  }
}
