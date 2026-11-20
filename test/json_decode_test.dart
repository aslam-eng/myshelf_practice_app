import 'dart:convert';

void main() {
  final jsonText = '{"title":"Travel Mug","price":19.99}';

  final data = jsonDecode(jsonText);

  print(data['title']);
  print(data['price']); // This will print 19.99 since 'price' is  in the JSON
}