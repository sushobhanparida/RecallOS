class SharedStack {
  final String id;
  final String name;
  final List<String> imageUrls;

  const SharedStack({
    required this.id,
    required this.name,
    required this.imageUrls,
  });

  factory SharedStack.fromMap(Map<String, dynamic> map) => SharedStack(
        id: map['id'] as String,
        name: map['stack_name'] as String,
        imageUrls: List<String>.from(map['image_urls'] as List),
      );
}
