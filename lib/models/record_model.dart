class RecordModel {
  RecordModel({
    this.id,
    this.api,
    this.vid,
    this.tid,
    this.type,
    this.name,
    this.pic,
    this.collected,
    this.anthologyName,
    this.progress,
    this.playedTime,
    this.createAt,
    this.updateAt,
  });

  RecordModel.fromJson(dynamic json) {
    id = json['id'] as int?;
    api = json['api'] as String?;
    vid = json['vid'] as String?;
    tid = json['tid'] as String?;
    type = json['type'] as String?;
    name = json['name'] as String?;
    pic = json['pic'] as String?;
    collected = json['collected'] as int?;
    anthologyName = json['anthologyName'] as String?;
    progress = json['progress'] as double?;
    playedTime = json['playedTime'] as int?;
    createAt = json['createAt'] as int?;
    updateAt = json['updateAt'] as int?;
  }

  int? id;
  String? api; // 视频源API地址
  String? vid; // 视频ID
  String? tid; // 分类ID
  String? type; // 分类名称
  String? name; // 标题名
  String? pic; // 缩略图

  int? collected; // 收藏状态  0-未收藏   1-已收藏
  String? anthologyName; // 播放选集名
  double? progress; // 播放进度  0~1
  int? playedTime; // 已播放时长，单位：毫秒
  int? createAt; // 记录时间   时间戳
  int? updateAt; // 更新时间   时间戳


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['api'] = api;
    data['vid'] = vid;
    data['tid'] = tid;
    data['type'] = type;
    data['name'] = name;
    data['pic'] = pic;
    data['collected'] = collected;
    data['anthologyName'] = anthologyName;
    data['progress'] = progress;
    data['playedTime'] = playedTime;
    data['createAt'] = createAt;
    data['updateAt'] = updateAt;
    return data;
  }
}
