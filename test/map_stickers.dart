// ignore_for_file: avoid_print

// No imports needed for basic print testing

void main() {
  final faces = ['U', 'D', 'F', 'B', 'R', 'L'];
  print('CubeState Sticker Mapping:');
  for (int f = 0; f < 6; f++) {
    print('Face ${faces[f]}:');
    for (int i = 0; i < 9; i++) {
      print('  ${faces[f]}$i: index ${f * 9 + i}');
    }
  }
}
