import 'dart:collection';

class RateLimiter {
  final int maxRequests;
  final Duration window;
  final Map<String, Queue<DateTime>> _buckets = {};

  RateLimiter({required this.maxRequests, required this.window});

  bool allow(String key) {
    final now = DateTime.now();
    final cutoff = now.subtract(window);
    final q = _buckets.putIfAbsent(key, () => Queue<DateTime>());
    while (q.isNotEmpty && q.first.isBefore(cutoff)) {
      q.removeFirst();
    }
    if (q.length >= maxRequests) return false;
    q.addLast(now);
    return true;
  }
}


