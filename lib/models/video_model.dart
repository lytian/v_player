/// 视频实体类
class VideoModel {
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
    this.anthologies,});

  VideoModel.fromJson(dynamic json) {
    if (json['vod_id'] != null) {
      id = json['vod_id'].toString();
    }
    name = json['vod_name'] as String?;
    if (json['vod_cid'] != null || json['type_id'] != null) {
      tid = (json['vod_cid'] ?? json['type_id']).toString();
    }
    type = (json['category'] ?? json['type_name']) as String?;
    pic = json['vod_pic'] as String;
    lang = (json['vod_lang'] ?? json['vod_language']) as String?;
    area = json['vod_area'] as String?;
    year = json['vod_year'] as String?;
    last = (json['vod_addtime'] ?? json['vod_pubdate']) as String?;
    state = json['state'] as String?;
    note = (json['vod_note'] ?? json['vod_remarks']) as String?;
    actor = json['vod_actor'] as String?;
    director = json['vod_director'] as String?;
    des = json['vod_content'] as String?;
    if (json['anthologies'] != null) {
      anthologies = [];
      json['anthologies'].forEach((Map<String, Object> e) {
        anthologies!.add(Anthology.fromJSON(e));
      });
    }
  }

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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['vod_id'] = id;
    data['vod_name'] = name;
    data['type_name'] = type;
    data['type_id'] = tid;
    data['vod_pic'] = pic;
    data['vod_lang'] = lang;
    data['vod_area'] = area;
    data['vod_year'] = year;
    data['vod_addtime'] = last;
    data['state'] = state;
    data['vod_note'] = note;
    data['vod_actor'] = actor;
    data['vod_director'] = director;
    data['vod_content'] = des;
    if (anthologies != null) {
      data['anthologies'] = anthologies!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

/// 选集
class Anthology {

  Anthology({
    this.name,
    this.url,
    this.tag,
  });

  Anthology.fromJSON(Map<String, dynamic> json) {
    name = json['name'] as String?;
    url = json['tid'] as String?;
    tag = json['tag'] as String?;
  }

  String? name;
  String? url;
  String? tag;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['url'] = url;
    data['tag'] = tag;
    return data;
  }
}
