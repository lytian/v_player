class SourceModel {
  SourceModel(
      {this.id,
      this.name,
      this.url,
      this.httpApi,
      this.type,});

  SourceModel.fromJson(dynamic json) {
    id = json['id'] as int?;
    name = json['name'] as String?;
    url = json['url'] as String?;
    httpApi = json['httpApi'] as String?;
    type = json['type'] as String?;
  }

  int? id;
  String? name;
  String? url;
  String? httpApi;
  String? type;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['url'] = url;
    data['httpApi'] = httpApi;
    data['type'] = type;
    return data;
  }
}
