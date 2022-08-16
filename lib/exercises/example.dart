import 'package:flutter/material.dart';

class TestUpdateState extends StatefulWidget {
  final String title;
  const TestUpdateState({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  State<TestUpdateState> createState() => _TestUpdateStateState();
}

class _TestUpdateStateState extends State<TestUpdateState> {
  int _count = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('TestUpdateState by didChangeDependencies');
  }

  @override
  void didUpdateWidget(covariant TestUpdateState oldWidget) {
    print('TestUpdateState by didUpdateWidget');
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    print('TestUpdateState: $_count');

    // MediaQuery.of(context).boldText;

    context.dependOnInheritedWidgetOfExactType<TestInherited>();

    return Center(
      child: Column(
        children: [
          Text('count: $_count'),
          IconButton(
            onPressed: () {
              _count += 1;
              setState(() {
                print('TestUpdateState by setState');
              });
            },
            icon: const Icon(
              Icons.add,
            ),
          )
        ],
      ),
    );
  }
}

class TestInherited extends InheritedWidget {
  const TestInherited({
    Key? key,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant TestInherited oldWidget) => true;
}
