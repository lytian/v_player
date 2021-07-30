class DownloadModel {
  int? id;
  String? api; // 视频源API地址
  String? vid; // 视频ID
  String? tid; // 分类ID
  String? type; // 分类名称
  String? name; // 标题名
  String? pic; // 缩略图
  String? url; // 下载地址

  String? fileId; // 文件保存ID
  DownloadStatus? status; // 下载状态
  double? progress; // 下载进度  0~1
  String? savePath; // 保存路径

  DownloadModel({
    this.id,
    this.api,
    this.vid,
    this.tid,
    this.type,
    this.name,
    this.pic,
    this.url,
    this.fileId,
    this.status,
    this.progress,
    this.savePath
  });

  DownloadModel.fromJson(Map<String, dynamic> json) {
    this.id = json['id'];
    this.api = json['api'];
    this.vid = json['vid'];
    this.tid = json['tid'];
    this.type = json['type'];
    this.name = json['name'];
    this.pic = json['pic'];
    this.url = json['url'];
    this.fileId = json['fileId'];
    if (json['status'] != null) {
      this.status = DownloadStatus.values[json['status']];
    }
    this.progress = json['progress'];
    this.savePath = json['savePath'];
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
    data['url'] = this.url;
    data['fileId'] = this.fileId;
    data['status'] = this.status?.index;
    data['progress'] = this.progress;
    data['savePath'] = this.savePath;
    return data;
  }
}

/// 下载状态
enum DownloadStatus {
  // 不需要下载
  NONE,
  // 等待下载
  WAITING,
  // 正在下载
  RUNNING,
  // 下载成功
  SUCCESS,
  // 下载失败
  FAIL
}