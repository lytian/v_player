class SourceModel {
  int? id;
  String? name;
  String? url;
  String? httpApi;
  String? type;

  SourceModel(
      {this.id,
      this.name,
      this.url,
      this.httpApi,
      this.type,});

  SourceModel.fromJson(Map json) {
    id = json['id'];
    name = json['name'];
    url = json['url'];
    httpApi = json['httpApi'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['url'] = this.url;
    data['httpApi'] = this.httpApi;
    data['type'] = this.type;
    return data;
  }
}
