void main() {
  final Map<String, String> m = {'id': '1'};
  try {
    final Map<String, dynamic> m2 = m as Map<String, dynamic>;
    print('Cast success');
  } catch (e) {
    print('Cast failed: $e');
  }
}
