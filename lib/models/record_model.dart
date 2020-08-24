class RecordModel {
  int id;
  String api; // 视频源API地址
  String vid; // 视频ID
  String tid; // 分类ID
  String type; // 分类名称
  String name; // 标题名
  String pic; // 缩略图

  int collected; // 收藏状态  0-未收藏   1-已收藏
  String anthologyName; // 播放选集名
  double progress; // 播放进度  0~1
  int playedTime; // 已播放时长，单位：毫秒
  int createAt; // 记录时间   时间戳
  int updateAt; // 更新时间   时间戳

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
    this.updateAt
  });

  RecordModel.fromJson(Map<String, dynamic> json) {
    this.id = json['id'];
    this.api = json['api'];
    this.vid = json['vid'];
    this.tid = json['tid'];
    this.type = json['type'];
    this.name = json['name'];
    this.pic = json['pic'];
    this.collected = json['collected'];
    this.anthologyName = json['anthologyName'];
    this.progress = json['progress'];
    this.playedTime = json['playedTime'];
    this.createAt = json['createAt'];
    this.updateAt = json['updateAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['api'] = this.api;
    data['vid'] = this.vid;
    data['tid'] = this.tid;
    data['type'] = this.type;
    data['name'] = this.name;
    data['pic'] = this.pic;
    data['collected'] = this.collected;
    data['anthologyName'] = this.anthologyName;
    data['progress'] = this.progress;
    data['playedTime'] = this.playedTime;
    data['createAt'] = this.createAt;
    data['updateAt'] = this.updateAt;
    return data;
  }
}