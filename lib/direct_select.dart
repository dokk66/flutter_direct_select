import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class DirectSelect extends StatefulWidget {
  /// Widget child you'll tap to display the Selection List
  final Widget child;

  /// List of Widgets you'll display after you tap the child
  final List<Widget> items;

  /// Listener when you select any item from the Selection List
  final ValueChanged<int> onSelectedItemChanged;

  /// Height of each Item of the Selection List
  final double itemExtent;

  /// Selected index of your selection list
  final int selectedIndex;

  const DirectSelect({
    Key key,
    this.selectedIndex,
    @required this.child,
    @required this.items,
    @required this.onSelectedItemChanged,
    @required this.itemExtent,
  })  : assert(child != null),
        assert(onSelectedItemChanged != null),
        assert(itemExtent != null),
        super(key: key);

  @override
  _DirectSelectState createState() => _DirectSelectState();
}

class _DirectSelectState extends State<DirectSelect> {
  FixedExtentScrollController _controller;
  OverlayEntry _overlayEntry;
  GlobalKey _key = GlobalKey();
  GlobalKey<MySelectionOverlayState> _keyOverlay = GlobalKey();
  int _currentIndex;

  _createOverlay() async {
    RenderBox box = _key.currentContext.findRenderObject();
    final position = box.localToGlobal(Offset.zero);
    final half = MediaQuery.of(context).size.height / 2;
    final result = -half + position.dy;
    final itemSize = widget.itemExtent;
    OverlayState overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => MySelectionOverlay(
            key: _keyOverlay,
            top: result + itemSize,
            child: MySelectionList(
              itemExtent: widget.itemExtent,
              childCount: widget.items != null ? widget.items.length : 0,
              onSelectedItemChanged: (index) {
                if (index != null) {
                  _currentIndex = index;
                }
              },
              builder: (context, index) {
                if (widget.items != null) {
                  return widget.items[index];
                }
              },
              controller: _controller,
            ),
          ),
    );

    overlayState.insert(_overlayEntry);
  }

  _removeOverlay() {
    _keyOverlay.currentState.reverse(_overlayEntry);
    widget.onSelectedItemChanged(_currentIndex);
  }

  @override
  void didUpdateWidget(DirectSelect oldWidget) {
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _currentIndex = widget.selectedIndex;
      _controller.dispose();
      _controller = FixedExtentScrollController(
        initialItem: widget.selectedIndex,
      );
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _currentIndex = widget.selectedIndex ?? 0;
    _controller = FixedExtentScrollController(
      initialItem: widget.selectedIndex,
    );
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: (_) => _createOverlay(),
      onVerticalDragEnd: (_) => _removeOverlay(),
      onVerticalDragUpdate: (details) =>
          _controller.jumpTo(_controller.offset - details.primaryDelta),
      child: Container(
        key: _key,
        child: widget.child,
      ),
    );
  }
}

class MySelectionOverlay extends StatefulWidget {
  final double top;
  final Widget child;
  final double bottom;

  const MySelectionOverlay({
    Key key,
    this.top,
    this.bottom,
    this.child,
  }) : super(key: key);

  @override
  MySelectionOverlayState createState() {
    return new MySelectionOverlayState();
  }
}

class MySelectionOverlayState extends State<MySelectionOverlay>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
        vsync: this,
        lowerBound: 0.7,
        upperBound: 1.0,
        duration: Duration(milliseconds: 200));
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.forward();
    return Stack(
      children: <Widget>[
        Positioned.fill(
          top: 0.0,
          left: 0.0,
          child: Container(
            color: Colors.white,
          ),
        ),
        Positioned(
          top: widget.top,
          left: 0.0,
          right: 0.0,
          bottom: widget.bottom,
          child: FadeTransition(
            opacity: _controller,
            child: ScaleTransition(
              scale: _controller,
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }

  void reverse(OverlayEntry overlayEntry) {
    _controller.reverse().whenComplete(() => overlayEntry.remove());
  }
}

class MySelectionList extends StatelessWidget {
  final FixedExtentScrollController controller;
  final IndexedWidgetBuilder builder;
  final int childCount;
  final ValueChanged<int> onSelectedItemChanged;
  final double itemExtent;

  const MySelectionList({
    Key key,
    @required this.controller,
    @required this.builder,
    @required this.childCount,
    @required this.onSelectedItemChanged,
    @required this.itemExtent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Container(
          height: MediaQuery.of(context).size.height,
          child: CupertinoPicker.builder(
            scrollController: controller,
            offAxisFraction: 0.0,
            itemExtent: itemExtent,
            childCount: childCount,
            useMagnifier: true,
            magnification: 1.25,
            diameterRatio: 3.0,
            backgroundColor: Colors.white,
            onSelectedItemChanged: onSelectedItemChanged,
            itemBuilder: builder,
          )),
    );
  }
}
