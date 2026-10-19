class Attraction {
  final int id;
  final String name;
  final String province;
  final List<String> imageUrls; // เปลี่ยนเป็น List<String> เพื่อเก็บหลายรูป
  final String description;
  final double rating;

  Attraction({
    required this.id,
    required this.name,
    required this.province,
    required this.imageUrls,
    required this.description,
    required this.rating,
  });
}