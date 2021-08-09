/// 视频实体类
class VideoModel {
  String? id;
  String? tid; // 分类ID
  String? type; // 分类名称
  String? name; // 标题名
  String? pic; // 缩略图

  String? lang; // 语言
  String? area; // 地区
  String? year; // 年份
  String? last;  // 上传时间
  String? state;
  String? note; // 标签
  String? actor; // 演员
  String? director; // 导演
  String? des; // 描述
  List<Anthology>? anthologies; // 选集列表

  VideoModel({
    this.id,
    this.name,
    this.tid,
    this.type,
    this.pic,
    this.lang,
    this.area,
    this.year,
    this.last,
    this.state,
    this.note,
    this.actor,
    this.director,
    this.des,
    this.anthologies});

  VideoModel.fromJson(Map<String, dynamic> json) {
    if (json['vod_id'] != null) {
      this.id = json['vod_id'].toString();
    }
    this.name = json['vod_name'];
    if (json['vod_cid'] != null || json['type_id'] != null) {
      this.tid = (json['vod_cid'] ?? json['type_id']).toString();
    }
    this.type = json['category'] ?? json['type_name'];
    this.pic = json['vod_pic'];
    this.lang = json['vod_lang'] ?? json['vod_language'];
    this.area = json['vod_area'];
    this.year = json['vod_year'];
    this.last = json['vod_addtime'] ?? json['vod_pubdate'];
    this.state = json['state'];
    this.note = json['vod_note'] ?? json['vod_remarks'];
    this.actor = json['vod_actor'];
    this.director = json['vod_director'];
    this.des = json['vod_content'];
    if (json['anthologies'] != null) {
      this.anthologies = [];
      json['anthologies'].forEach((e) {
        this.anthologies!.add(Anthology.fromJSON(e));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['vod_id'] = this.id;
    data['vod_name'] = this.name;
    data['type_name'] = this.type;
    data['type_id'] = this.tid;
    data['vod_pic'] = this.pic;
    data['vod_lang'] = this.lang;
    data['vod_area'] = this.area;
    data['vod_year'] = this.year;
    data['vod_addtime'] = this.last;
    data['state'] = this.state;
    data['vod_note'] = this.note;
    data['vod_actor'] = this.actor;
    data['vod_director'] = this.director;
    data['vod_content'] = this.des;
    if (this.anthologies != null) {
      data['anthologies'] = this.anthologies!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

/// 选集
class Anthology {
  String? name;
  String? url;

  Anthology({required this.name, required this.url});

  Anthology.fromJSON(Map<String, dynamic> json) {
    name = json['name'];
    url = json['tid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['url'] = this.url;
    return data;
  }
}