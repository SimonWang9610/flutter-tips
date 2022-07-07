import 'package:flutter/material.dart';

typedef CardChecker = void Function(String);

class CustomCard extends StatelessWidget {
  final CardChecker onChecked;
  final bool checked;
  final String name;
  final String desc;
  const CustomCard({
    Key? key,
    required this.name,
    required this.desc,
    required this.onChecked,
    this.checked = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: checked ? Colors.lightBlueAccent : Colors.black,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      textAlign: TextAlign.start,
                    ),
                    checked
                        ? const Icon(
                            Icons.check_box_rounded,
                            color: Colors.greenAccent,
                          )
                        : const Icon(
                            Icons.check_box_rounded,
                            color: Colors.grey,
                          )
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: Text('image'),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  desc,
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),
        ),
      ),
      onTap: () => onChecked(name),
    );
  }
}

class CustomGrid extends StatefulWidget {
  const CustomGrid({Key? key}) : super(key: key);

  @override
  State<CustomGrid> createState() => _CustomGridState();
}

class _CustomGridState extends State<CustomGrid> {
  final List<String> cards = ['deeper', 'moment', 'code', 'babylon'];

  String checked = 'deeper';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('title'),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            children: cards
                .map(
                  (card) => ConstrainedBox(
                    constraints: BoxConstraints.tight(Size.square(200)),
                    child: CustomCard(
                      name: card,
                      desc: card,
                      checked: checked == card,
                      onChecked: _onChecked,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  void _onChecked(String card) {
    checked = card;
    setState(() {});
  }
}
