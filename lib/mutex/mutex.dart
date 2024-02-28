import 'dart:async';
import 'dart:collection';

class Mutex {
  final Queue<Completer<Lock>> _queue = Queue();

  Future<Lock> _acquire() {
    final completer = Completer<Lock>();
    if (_queue.isEmpty) {
      completer.complete(Lock._(this));
    }
    _queue.addLast(completer);
    return completer.future;
  }

  void _release() {
    assert(_queue.isNotEmpty, 'No lock to release');
    assert(_queue.first.isCompleted, 'Lock is not completed');
    _queue.removeFirst();
    if (_queue.isNotEmpty) {
      _queue.first.complete(Lock._(this));
    }
  }

  FutureOr<T> lock<T>(FutureOr<T> Function() callback) async {
    final lock = await _acquire();
    try {
      return await callback();
    } finally {
      lock.release();
    }
  }

  bool get locked => _queue.isNotEmpty;
}

class Lock {
  Mutex? _mutex;

  Lock._(this._mutex);

  void release() {
    assert(_mutex != null, 'Lock is already released');
    final mutex = _mutex;
    _mutex = null;
    mutex?._release();
  }
}
