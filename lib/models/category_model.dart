class CategoryModel {
  String? id;
  String? name;

  CategoryModel(
      {this.id,
      this.name});

  CategoryModel.fromJson(Map<String, dynamic> json) {
    if (json['type_id'] != null || json['cid'] != null) {
      id = (json['type_id'] ?? json['cid']).toString();
    }
    name = json['type_name'] ?? json['title'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type_id'] = this.id;
    data['type_name'] = this.name;
    return data;
  }
}
