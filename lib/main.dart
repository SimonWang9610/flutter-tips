import 'package:flutter/material.dart';
import 'package:flutter_tips/positioned_list/observer/multi_child_observer.dart';
import 'positioned_list/positioned_list_delegate.dart';
import 'positioned_list/custom_scroll_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      // home: const MyHomePage(
      //   title: 'my home page',
      // ),
      home: const MyHomePage(title: "List Example"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: const ListExample(),
    );
  }
}

class ListExample extends StatefulWidget {
  const ListExample({super.key});

  @override
  State<ListExample> createState() => _ListExampleState();
}

class _ListExampleState extends State<ListExample> {
  final CustomScrollController _controller = CustomScrollController();

  int _itemCount = 30;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _controller.addListener(_listenOnstageItem);
        // _controller.scrollExtent.addListener(() {
        //   print(_controller.scrollExtent.value);
        // });
        // final maxExtent = _controller.position.maxScrollExtent;

        // _controller.jumpTo(maxExtent);
        // print("max scroll extent: $maxExtent");
      },
    );
  }

  void _listenOnstageItem() {
    final observer = _controller.createOrObtainObserver("first");

    List<int> onstageItems = [];
    for (final key in observer.models.keys) {
      if (observer.isOnStage(
        key,
        scrollExtent: _controller.scrollExtent.value,
      )) {
        onstageItems.add(key);
      }
    }

    print(onstageItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ScrollJumper(
            onJump: _onJump,
          ),
          Expanded(
            child: CustomScrollView(
              controller: _controller,
              reverse: false,
              scrollDirection: Axis.vertical,
              slivers: [
                SliverList(
                  delegate: PositionedChildBuilderDelegate(
                    childCount: _itemCount,
                    (context, index) => IndexedItem(
                      index: index,
                      label: "First",
                    ),
                    addRepaintBoundaries: false,
                    addSemanticIndexes: true,
                    addAutomaticKeepAlives: true,
                    observer: _controller.createOrObtainObserver("first")
                        as MultiChildScrollObserver,
                  ),
                ),
                SliverGrid(
                  delegate: PositionedChildBuilderDelegate(
                    childCount: _itemCount,
                    (context, index) => ListTile(
                      key: ValueKey<int>(index),
                      leading: const CircleAvatar(
                        child: Text("Grid"),
                      ),
                      title: Text("Grid $index"),
                      // subtitle: Text("${widget.index}" * widget.index),
                    ),
                    addRepaintBoundaries: false,
                    addSemanticIndexes: true,
                    addAutomaticKeepAlives: true,
                    observer: _controller.createOrObtainObserver("second")
                        as MultiChildScrollObserver,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 100,
                  ),
                  sliver: SliverList(
                    delegate: PositionedChildBuilderDelegate(
                      childCount: _itemCount,
                      (context, index) => IndexedItem(
                        index: index,
                        label: "Forth",
                      ),
                      addRepaintBoundaries: false,
                      addSemanticIndexes: true,
                      addAutomaticKeepAlives: true,
                      observer: _controller.createOrObtainObserver("forth")
                          as MultiChildScrollObserver,
                    ),
                  ),
                ),

                // SliverList(
                //   delegate: SliverChildBuilderDelegate(
                //     (context, index) => ItemProxy(
                //       observer: _controller.createOrObtainObserver("third"),
                //       child: IndexedItem(label: "third", index: index),
                //     ),
                //     childCount: _itemCount,
                //   ),
                // ),
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _show,
        child: const Icon(Icons.arrow_back),
      ),
    );
  }

  void _show() {
    _controller.showInViewport("forth");
  }

  void _onJump(int index) {
    _controller.jumpToIndex(
      index,
      whichObserver: "forth",
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class IndexedItem extends StatefulWidget {
  final String label;
  final int index;

  const IndexedItem({
    super.key,
    required this.label,
    required this.index,
  });

  @override
  State<IndexedItem> createState() => _IndexedItemState();
}

class _IndexedItemState extends State<IndexedItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    print("disposing: ${widget.index}");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListTile(
      key: ValueKey<int>(widget.index),
      leading: CircleAvatar(
        child: Text("${widget.label}"),
      ),
      title: Text("${widget.label} ${widget.index}"),
      subtitle: Text("${widget.index}" * widget.index),
    );
  }
}

class ScrollJumper extends StatefulWidget {
  final ValueChanged<int> onJump;
  const ScrollJumper({
    super.key,
    required this.onJump,
  });

  @override
  State<ScrollJumper> createState() => _ScrollJumperState();
}

class _ScrollJumperState extends State<ScrollJumper> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            onPressed: () {
              final index = int.tryParse(_controller.text);

              if (index != null) {
                widget.onJump(index);
              }
            },
            icon: const Icon(Icons.add),
          )),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
