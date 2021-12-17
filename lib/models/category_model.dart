class CategoryModel {
  CategoryModel({
    this.id,
    this.name,
  });

  CategoryModel.fromJson(dynamic json) {
    if (json['type_id'] != null || json['cid'] != null) {
      id = (json['type_id'] ?? json['cid']).toString();
    }
    name = (json['type_name'] ?? json['title']) as String?;
  }

  String? id;
  String? name;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type_id'] = id;
    data['type_name'] = name;
    return data;
  }
}
