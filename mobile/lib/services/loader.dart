import 'package:flutter/material.dart';
import '../widgets/common.dart';
import 'api_client.dart' show errMsg;

/// Registered once on MaterialApp (see main.dart) so DataLoader can tell when a
/// screen comes back into view — for example after popping back from "Add Member".
final RouteObserver<PageRoute> appRouteObserver = RouteObserver<PageRoute>();

/// Loads data with [load] on first build, and reloads every time this screen
/// becomes the visible route again (equivalent to React Navigation's useFocusEffect).
class DataLoader<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;
  final List<Object?> watch; // when any of these change, reload from scratch
  const DataLoader({super.key, required this.load, required this.builder, this.watch = const []});

  @override
  State<DataLoader<T>> createState() => _DataLoaderState<T>();
}

class _DataLoaderState<T> extends State<DataLoader<T>> with RouteAware {
  T? _data;
  bool _loading = true;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void didUpdateWidget(covariant DataLoader<T> old) {
    super.didUpdateWidget(old);
    if (!_sameList(old.watch, widget.watch)) _run();
  }

  bool _sameList(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void didPopNext() => _run(silent: true);

  Future<void> _run({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = null; });
    try {
      final d = await widget.load();
      if (!mounted) return;
      setState(() { _data = d; _loading = false; _error = null; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) return const LoadingBox();
    if (_error != null && _data == null) {
      return ErrorBox(message: errMsg(_error!), onRetry: () => _run());
    }
    return widget.builder(context, _data as T, () => _run());
  }
}
